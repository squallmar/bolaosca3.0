  
document.querySelectorAll('.nav-link').forEach(link => {
  link.addEventListener('click', function(e) {
    const x = e.clientX - e.target.getBoundingClientRect().left;
    const y = e.clientY - e.target.getBoundingClientRect().top;
    
    const ripple = document.createElement('span');
    ripple.style.left = `${x}px`;
    ripple.style.top = `${y}px`;
    ripple.classList.add('ripple-effect');
    
    this.appendChild(ripple);
    
    setTimeout(() => {
      ripple.remove();
    }, 600);
  });
});

document.addEventListener('turbo:load', function() {
  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl)
  })
})