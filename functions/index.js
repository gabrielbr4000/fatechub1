const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.notificarNovaAtividade = functions.firestore
  .document('turmas/{turmaId}/atividades/{atividadeId}')
  .onCreate(async (snap, context) => {
    const atividade = snap.data();
    const turmaId = context.params.turmaId; // ex: "ALG-L-P-MANHA"

    console.log(`Nova atividade: "${atividade.nome}" | Turma: ${turmaId}`);

    // Extrai turno e semestre do ID da turma
    // ALG-L-P-MANHA  → turno: "MANHA", semestreRomano: "P" ← não é romano aqui
    // BD-I-MANHA     → turno: "MANHA", semestreRomano: "I"
    // INGLES-I-MANHA → turno: "MANHA", semestreRomano: "I"
    const partes = turmaId.split('-');
    const turno = partes[partes.length - 1];           // última parte → "MANHA"
    const semestreRomano = partes[partes.length - 2];  // penúltima → "I", "II"...

    const semestreMap = {
      'I': 1, 'II': 2, 'III': 3,
      'IV': 4, 'V': 5, 'VI': 6,
    };
    const semestre = semestreMap[semestreRomano];

    if (!semestre) {
      console.log(`Semestre não reconhecido: "${semestreRomano}" do turmaId: ${turmaId}`);
      return null;
    }

    console.log(`Turno: ${turno} | Semestre: ${semestre}`);

    // Busca alunos com mesmo semestre e turno
    const alunosSnap = await admin.firestore()
      .collection('usuarios')
      .where('perfil', '==', 'aluno')
      .where('semestre', '==', semestre)
      .where('turno', '==', turno)
      .get();

    if (alunosSnap.empty) {
      console.log(`Nenhum aluno para semestre ${semestre} turno ${turno}`);
      return null;
    }

    console.log(`Alunos encontrados: ${alunosSnap.size}`);

    // Coleta tokens FCM válidos
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
        atividadeId: context.params.atividadeId,
        nome: atividade.nome ?? '',
        disciplina: atividade.disciplina ?? '',
        dataEntrega: atividade.dataEntrega ?? '',
      },
      tokens: tokens,
    };

    const resultado = await admin.messaging().sendEachForMulticast(mensagem);
    console.log(`✅ Enviadas: ${resultado.successCount} | ❌ Falhas: ${resultado.failureCount}`);

    // Remove tokens inválidos do Firestore
    if (resultado.failureCount > 0) {
      const tokensInvalidos = [];
      resultado.responses.forEach((resp, i) => {
        if (!resp.success) {
          tokensInvalidos.push(tokens[i]);
          console.log(`❌ Token inválido: ${tokens[i]} — ${resp.error?.message}`);
        }
      });

      // Limpa em lotes de 10 (limite do Firestore para 'in')
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
          batch.update(doc.ref, {
            fcmToken: admin.firestore.FieldValue.delete(),
          });
        });
        await batch.commit();
      }

      console.log(`🧹 ${tokensInvalidos.length} tokens inválidos removidos`);
    }

    return null;
});