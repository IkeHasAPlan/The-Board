(function () {
  const TWO_MINUTES = 2 * 60 * 1000;

  const path = window.location.pathname.toLowerCase();

  // NEVER timeout the actual board UI
  if (path === "/board" || path.startsWith("/board/")) {
    return;
  }

  setTimeout(() => {
    sessionStorage.removeItem("userRole");
    sessionStorage.removeItem("displayName");
    window.location.href = "/index.html";
  }, TWO_MINUTES);
})();