rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Regras da coleção de eventos
    match /events/{eventId} {
      // Qualquer usuário autenticado pode ver eventos
      allow read: if request.auth != null;

      // Criar: somente o dono do evento
      allow create: if request.auth != null && request.resource.data.hostId == request.auth.uid;

      // Atualizar: somente o dono
      allow update: if request.auth != null && request.auth.uid == resource.data.hostId;

      // Excluir: somente o dono do evento
      allow delete: if request.auth != null && request.auth.uid == resource.data.hostId;
    }

    // Subcoleções dos usuários (ex: convites)
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /event_invites/{inviteId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
