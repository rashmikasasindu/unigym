rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ── Helper Functions ────────────────────────────────────
    // Is the request from a signed-in, email-verified user?
    function isVerifiedUser() {
      return request.auth != null && request.auth.token.email_verified == true;
    }

    // Does the signed-in user have a specific role in Firestore?
    function hasRole(role) {
      return isVerifiedUser() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role.lower() == role;
    }

    function isAdmin()      { return hasRole('admin'); }
    function isInstructor() { return hasRole('instructor'); }
    function isOwnDoc(uid)  { return isVerifiedUser() && request.auth.uid == uid; }

    // ── users/{uid} ─────────────────────────────────────────
    match /users/{uid} {
      // Any verified user can read their own profile.
      // Admins can read any profile (for admin dashboard).
      allow read: if isOwnDoc(uid) || isAdmin();

      // ⚠️ IMPORTANT: Do NOT require email_verified here.
      // During signup, the user is authenticated but not yet verified.
      // The Firestore write happens immediately after account creation.
      allow create: if request.auth != null
        && request.auth.uid == uid
        && request.resource.data.keys().hasAll(['uid','name','email','role','gender'])
        && request.resource.data.role == 'User'; // default role only — no self-promotion

      // Users can update their own profile but cannot change their role.
      // Admins can update any profile (e.g., to assign instructor role).
      allow update: if (isOwnDoc(uid) && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['role']))
                    || isAdmin();

      // Only admins can delete user records.
      allow delete: if isAdmin();
    }

    // ── reservations/{reservationId} ─────────────────────────────
    match /reservations/{reservationId} {
      // Users can read their own reservation docs (get).
      // Admins and instructors can read any (for QR scanning / management).
      allow get: if isVerifiedUser() &&
        (resource.data.userId == request.auth.uid || isAdmin() || isInstructor());

      // Any verified user can list reservations (needed to count available slots).
      // Individual document access is still restricted by the 'get' rule above.
      allow list: if isVerifiedUser();

      // A verified user can create a reservation only for themselves.
      // Only allow bookings for today, tomorrow, or day after tomorrow.
      // attended must start as false.
      allow create: if isVerifiedUser()
        && request.resource.data.userId == request.auth.uid
        && request.resource.data.attended == false
        && request.resource.data.keys().hasAll(['userId','userName','date','timeMinutes','attended','createdAt'])
        && request.resource.data.date >= request.time.date()
        && request.resource.data.date <= request.time.date().addDuration(duration.value(2, 'd'));

      // Users can cancel (delete) their OWN reservations — but only if not yet attended.
      // Admins can delete any reservation.
      allow delete: if isAdmin()
        || (isVerifiedUser()
            && resource.data.userId == request.auth.uid
            && resource.data.attended == false);

      // Only admins/instructors can update reservations (e.g., mark attendance).
      // Users cannot edit reservations directly.
      allow update: if isAdmin() || isInstructor();
    }

  }
}
