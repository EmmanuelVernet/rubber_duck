// force align button in DOM
document.addEventListener("DOMContentLoaded", () => {
  const h1 = document.querySelector("h1");
  const duck = document.getElementById("rubber-duck-container");

  if (!h1 || !duck) return;

  h1.style.display = "flex";
  h1.style.alignItems = "center";

  h1.appendChild(duck);
});

// create modal & API call
(function () {
  // 1. Load Marked (Markdown) and Prism (Syntax Highlighting) libs
  const libs = [
    "https://cdn.jsdelivr.net/npm/marked/marked.min.js",
    "https://cdn.jsdelivr.net/npm/prismjs@1.29.0/prism.min.js",
    "https://cdn.jsdelivr.net/npm/prismjs@1.29.0/components/prism-ruby.min.js", // Support for Ruby
  ];

  libs.forEach((src) => {
    const script = document.createElement("script");
    script.src = src;
    document.head.appendChild(script);
  });

  // 2. Load Prism CSS for the theme (e.g., 'Tomorrow Night')
  const link = document.createElement("link");
  link.rel = "stylesheet";
  link.href =
    "https://cdn.jsdelivr.net/npm/prismjs@1.29.0/themes/prism-tomorrow.min.css";
  document.head.appendChild(link);

  const button = document.getElementById("rubber-duck-button");
  const modal = document.getElementById("rubber-duck-modal");
  const overlay = document.getElementById("rubber-duck-overlay");
  const closeBtn = document.getElementById("rubber-duck-close");
  const content = document.getElementById("rubber-duck-content");

  button.addEventListener("click", async () => {
    modal.style.display = "block";
    overlay.style.display = "block";
    content.innerHTML = "Analyzing error... This may take a few seconds.";

    try {
      const response = await fetch("/rubber_duck/analyze_error", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(errorData),
      });
      const result = await response.json();

      if (result.success) {
        content.innerHTML = window.marked.parse(result.response);
        // '<pre style="white-space: pre-wrap; font-family: system-ui;">' + window.marked.parse(result.response) + '</pre>';
        setTimeout(() => {
          if (window.Prism) {
            window.Prism.highlightAllUnder(content);
          }
        }, 100);
      } else {
        content.innerHTML =
          '<span style="color: #DC2626;">Error: ' +
          (result.error || "Unknown error") +
          "</span>";
      }
    } catch (error) {
      content.innerHTML =
        '<span style="color: #DC2626;">Failed to connect: ' +
        error.message +
        "</span>";
    }
  });

  function closeModal() {
    modal.style.display = "none";
    overlay.style.display = "none";
  }

  closeBtn.addEventListener("click", closeModal);
  overlay.addEventListener("click", closeModal);
})();
