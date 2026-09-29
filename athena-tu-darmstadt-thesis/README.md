# Trying to replicate my LaTeX thesis with Typst

```bash
nix build --out-link figures .#figures
nix build .#text-rdt-sbt-tests-thesis 
typst compile --root .. --font-path fonts/ main.typ
```