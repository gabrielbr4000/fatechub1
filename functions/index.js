const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

const LIMITE_FCM = 500; // máximo de tokens por chamada do sendEachForMulticast
const LIMITE_BATCH = 500; // máximo de escritas por batch do Firestore

// Só esses erros indicam que o token nunca mais vai funcionar
const ERROS_TOKEN_INVALIDO = [
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
];

function dividirEmLotes(lista, tamanho) {
  const lotes = [];
  for (let i = 0; i < lista.length; i += tamanho) {
    lotes.push(lista.slice(i, i + tamanho));
  }
  return lotes;
}

// Aceita string ou Timestamp do Firestore e devolve texto legível
function formatarData(valor) {
  if (!valor) return '';
  if (typeof valor.toDate === 'function') {
    return valor.toDate().toLocaleDateString('pt-BR', {
      timeZone: 'America/Sao_Paulo',
    });
  }
  return String(valor);
}

exports.notificarNovaAtividade = functions.firestore
  .document('turmas/{turmaId}/atividades/{atividadeId}')
  .onCreate(async (snap, context) => {
    const atividade = snap.data();
    const { turmaId, atividadeId } = context.params;

    console.log(`Nova atividade: "${atividade.nome}" | Turma: ${turmaId}`);

    // 1. Lê ciclo e turno direto do documento da turma
    const turmaSnap = await db.doc(`turmas/${turmaId}`).get();

    if (!turmaSnap.exists) {
      console.log(`Turma ${turmaId} não existe (documento sem campos?)`);
      return null;
    }

    const { ciclo, turno } = turmaSnap.data();

    if (ciclo == null || !turno) {
      console.log(`Turma ${turmaId} sem ciclo/turno definidos`);
      return null;
    }

    console.log(`Turma ${turmaId} → ciclo: ${ciclo} | turno: ${turno}`);

    // 2. Busca alunos do mesmo ciclo (campo "semestre" do usuário) e turno
    const alunosSnap = await db
      .collection('usuarios')
      .where('perfil', '==', 'aluno')
      .where('semestre', '==', ciclo)
      .where('turno', '==', turno)
      .get();

    if (alunosSnap.empty) {
      console.log(`Nenhum aluno para ciclo ${ciclo} turno ${turno}`);
      return null;
    }

    console.log(`Alunos encontrados: ${alunosSnap.size}`);

    // 3. Coleta tokens FCM, guardando a referência do usuário de cada um
    //    (assim dá para limpar tokens inválidos sem fazer outra query)
    const refPorToken = new Map();
    alunosSnap.forEach((doc) => {
      const token = doc.data().fcmToken;
      if (token) refPorToken.set(token, doc.ref);
    });

    const tokens = [...refPorToken.keys()];

    if (tokens.length === 0) {
      console.log('Nenhum token FCM — alunos sem login recente');
      return null;
    }

    console.log(`Enviando para ${tokens.length} dispositivos...`);

    // 4. Monta a mensagem (sem os tokens, que variam por lote)
    const dataEntrega = formatarData(atividade.dataEntrega);

    const mensagemBase = {
      notification: {
        title: '📚 Nova atividade publicada!',
        body: `${atividade.nome ?? 'Atividade'} — Entrega: ${dataEntrega || 'Sem prazo'}`,
      },
      data: {
        tipo: 'nova_atividade',
        turmaId: turmaId,
        atividadeId: atividadeId,
        nome: atividade.nome ?? '',
        disciplina: atividade.disciplina ?? '',
        dataEntrega: dataEntrega,
      },
    };

    // 5. Envia em lotes de até 500 tokens
    let enviadas = 0;
    let falhas = 0;
    const tokensInvalidos = [];

    for (const lote of dividirEmLotes(tokens, LIMITE_FCM)) {
      const resultado = await admin
        .messaging()
        .sendEachForMulticast({ ...mensagemBase, tokens: lote });

      enviadas += resultado.successCount;
      falhas += resultado.failureCount;

      resultado.responses.forEach((resp, i) => {
        if (resp.success) return;

        const codigo = resp.error?.code;
        console.log(`❌ Falha no token ${lote[i]} — ${codigo}: ${resp.error?.message}`);

        if (ERROS_TOKEN_INVALIDO.includes(codigo)) {
          tokensInvalidos.push(lote[i]);
        }
      });
    }

    console.log(`✅ Enviadas: ${enviadas} | ❌ Falhas: ${falhas}`);

    // 6. Remove apenas os tokens realmente inválidos
    if (tokensInvalidos.length > 0) {
      for (const lote of dividirEmLotes(tokensInvalidos, LIMITE_BATCH)) {
        const batch = db.batch();
        lote.forEach((token) => {
          batch.update(refPorToken.get(token), {
            fcmToken: admin.firestore.FieldValue.delete(),
          });
        });
        await batch.commit();
      }

      console.log(`🧹 ${tokensInvalidos.length} tokens inválidos removidos`);
    }

    return null;
  });