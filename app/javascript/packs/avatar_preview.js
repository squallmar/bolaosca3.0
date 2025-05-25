// app/javascript/packs/avatar_preview.js
document.addEventListener('turbo:load', () => {
  const avatarInput = document.getElementById('user_avatar');
  if (avatarInput) {
    avatarInput.addEventListener('change', (event) => {
      const file = event.target.files[0];
      const preview = document.getElementById('avatar-preview');
      
      if (file && preview) {
        preview.src = URL.createObjectURL(file);
      }
    });
  }
});