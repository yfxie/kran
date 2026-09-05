(function () {
  "use strict";

  var LANGUAGES = {
    sh: "shell", shell: "shell", bash: "shell", zsh: "shell", console: "shell",
    yaml: "yaml", yml: "yaml", json: "json", erb: "erb", ruby: "ruby",
    dockerfile: "dockerfile", diff: "diff", text: "output", plaintext: "output"
  };

  // "$ " starts a command, "> " continues one across a backslash break.
  var PROMPTS = ["$ ", "> "];

  var body = document.body;
  var COPY = body.getAttribute("data-copy") || "Copy";
  var COPIED = body.getAttribute("data-copied") || "Copied";

  // A console block interleaves commands, their output and `# ` comments.
  // Only the commands are worth putting on the clipboard.
  function copyableText(source, lang) {
    var text = source.textContent.replace(/\n$/, "");
    if (lang !== "console") return text;
    return text.split("\n")
      .filter(function (line) {
        return PROMPTS.some(function (p) { return line.indexOf(p) === 0; });
      })
      .map(function (line) { return line.slice(2); })
      .join("\n");
  }

  function copy(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text);
    }
    // http:// on a LAN address has no clipboard API.
    var field = document.createElement("textarea");
    field.value = text;
    field.setAttribute("readonly", "");
    field.style.position = "fixed";
    field.style.opacity = "0";
    document.body.appendChild(field);
    field.select();
    document.execCommand("copy");
    document.body.removeChild(field);
    return Promise.resolve();
  }

  function decorate(block) {
    var match = /language-([\w+#-]+)/.exec(block.className);
    var lang = match ? match[1] : "";
    var label = lang ? LANGUAGES[lang] || lang : "";
    var source = block.querySelector("pre");
    if (!source) return;

    var figure = document.createElement("figure");
    figure.className = "code";
    var head = document.createElement("figcaption");
    head.className = "code-head";
    head.innerHTML = '<span class="code-lang"></span>';
    head.firstChild.textContent = label;

    var button = document.createElement("button");
    button.type = "button";
    button.className = "code-copy";
    button.textContent = COPY;
    button.addEventListener("click", function () {
      copy(copyableText(source, lang)).then(function () {
        button.textContent = COPIED;
        button.setAttribute("data-copied", "");
        setTimeout(function () {
          button.textContent = COPY;
          button.removeAttribute("data-copied");
        }, 1400);
      });
    });
    head.appendChild(button);

    block.parentNode.insertBefore(figure, block);
    figure.appendChild(head);
    figure.appendChild(block);
  }

  function scrollable(table) {
    var wrapper = document.createElement("div");
    wrapper.className = "table-scroll";
    table.parentNode.insertBefore(wrapper, table);
    wrapper.appendChild(table);
  }

  var blocks = document.querySelectorAll(".content div.highlighter-rouge");
  for (var i = 0; i < blocks.length; i++) decorate(blocks[i]);

  var tables = document.querySelectorAll(".content > table");
  for (var j = 0; j < tables.length; j++) scrollable(tables[j]);

  var toggle = document.querySelector(".menu-toggle");
  if (toggle) {
    toggle.addEventListener("click", function () {
      var open = body.classList.toggle("nav-open");
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
    });
  }
})();
