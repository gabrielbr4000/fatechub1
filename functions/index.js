const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
admin.initializeApp();

exports.notificarNovaAtividade = onDocumentCreated(
  {
    document: 'turmas/{turmaId}/atividades/{atividadeId}',
    region: 'us-east1', // <- região do Firestore
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return null;

    const atividade = snap.data();
    const turmaId = event.params.turmaId;

    console.log(`Nova atividade: "${atividade.nome}" | Turma: ${turmaId}`);

    // Busca os dados da turma para pegar ciclo e turno
    const turmaDoc = await admin.firestore()
      .collection('turmas')
      .doc(turmaId)
      .get();

    if (!turmaDoc.exists) {
      console.log(`Turma não encontrada: ${turmaId}`);
      return null;
    }

    const turma = turmaDoc.data();
    const ciclo = turma.ciclo;   // ex: 1
    const turno = turma.turno;   // ex: "MANHA"

    console.log(`Ciclo: ${ciclo} | Turno: ${turno}`);

    // Busca alunos com mesmo semestre (ciclo) e turno
    const alunosSnap = await admin.firestore()
      .collection('usuarios')
      .where('perfil', '==', 'aluno')
      .where('semestre', '==', ciclo)  // ciclo da turma == semestre do aluno
      .where('turno', '==', turno)
      .get();
    
    console.log(`Query executada. Resultado: ${alunosSnap.size}`);

    if (alunosSnap.empty) {
      console.log(`Nenhum aluno para ciclo ${ciclo} turno ${turno}`);
      return null;
    }

    console.log(`Alunos encontrados: ${alunosSnap.size}`);

    const tokens = [];
    alunosSnap.forEach(doc => {
      const token = doc.data().fcmToken;
      if (token) tokens.push(token);
    });

    if (tokens.length === 0) {
      console.log('Nenhum token FCM — alunos sem login recente');
      return null;
    }

    console.log(`Enviando para ${tokens.length} dispositivos...`);

    const mensagem = {
      notification: {
        title: '📚 Nova atividade publicada!',
        body: `${atividade.nome} — Entrega: ${atividade.dataEntrega ?? 'Sem prazo'}`,
      },
      data: {
        tipo: 'nova_atividade',
        turmaId: turmaId,
        atividadeId: event.params.atividadeId,
        nome: atividade.nome ?? '',
        disciplina: atividade.disciplina ?? '',
        dataEntrega: atividade.dataEntrega ?? '',
      },
      tokens: tokens,
    };

    const resultado = await admin.messaging().sendEachForMulticast(mensagem);
    console.log(`✅ Enviadas: ${resultado.successCount} | ❌ Falhas: ${resultado.failureCount}`);

    if (resultado.failureCount > 0) {
      const tokensInvalidos = [];
      resultado.responses.forEach((resp, i) => {
        if (!resp.success) tokensInvalidos.push(tokens[i]);
      });

      const chunks = [];
      for (let i = 0; i < tokensInvalidos.length; i += 10) {
        chunks.push(tokensInvalidos.slice(i, i + 10));
      }

      for (const chunk of chunks) {
        const snapInvalidos = await admin.firestore()
          .collection('usuarios')
          .where('fcmToken', 'in', chunk)
          .get();

        const batch = admin.firestore().batch();
        snapInvalidos.forEach(doc => {
          batch.update(doc.ref, { fcmToken: admin.firestore.FieldValue.delete() });
        });
        await batch.commit();
      }
      console.log(`🧹 ${tokensInvalidos.length} tokens inválidos removidos`);
    }

    return null;
  }
);