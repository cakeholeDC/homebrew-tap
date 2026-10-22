class Chromaticli < Formula
  desc "Sync terminal colors with VSCode workspace themes"
  homepage "https://github.com/cakeholeDC/chromaticli"
  url "https://github.com/cakeholeDC/chromaticli/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "2ceca5e05c710df6679ade0e4a218e0b7a009e4ad069d5547ca88223ee1ee620"
  license "MIT"

  depends_on "jq"

  def install
    libexec.install "chromaticli", "hook.zsh", "hook.bash", "hook.fish", "themes.json"
    (libexec/"vscode-extension").install "vscode-extension/package.json",
                                         "vscode-extension/chromaticli-themes-0.0.1.vsix"
    (bin/"chromaticli").write_env_script opt_libexec/"chromaticli", CHROMATICLI_LIBEXEC: opt_libexec
  end

  def caveats
    <<~EOS
      Run `chromaticli install` to configure shell integration, then restart your shell.
      Keep VS Code's `code` CLI on PATH to remove shell integration with `chromaticli uninstall`.
      Before removing the formula, run `chromaticli uninstall` to remove shell integration.
    EOS
  end

  test do
    ENV["HOME"] = testpath
    ENV["XDG_CONFIG_HOME"] = testpath/".config"
    ENV["ZDOTDIR"] = testpath
    ENV["CHROMATICLI_TEST_CODE_STATE"] = testpath/"code-state"

    (testpath/"bin").mkpath
    (testpath/"bin/code").write <<~SH
      #!/bin/sh
      case "$1" in
        --list-extensions)
          if [ -f "$CHROMATICLI_TEST_CODE_STATE" ]; then
            if [ "${2:-}" = "--show-versions" ]; then
              printf '%s\n' 'chromaticli.chromaticli-themes@0.0.1'
            else
              printf '%s\n' 'chromaticli.chromaticli-themes'
            fi
          fi
          ;;
        --install-extension) printf '%s\n' "$2" > "$CHROMATICLI_TEST_CODE_STATE" ;;
        --uninstall-extension) rm -f "$CHROMATICLI_TEST_CODE_STATE" ;;
        *) exit 1 ;;
      esac
    SH
    (testpath/"bin/code").chmod 0755
    ENV.prepend_path "PATH", testpath/"bin"

    manifest = opt_libexec/"vscode-extension/package.json"
    vsix = opt_libexec/"vscode-extension/chromaticli-themes-0.0.1.vsix"
    assert_path_exists manifest
    assert_path_exists vsix

    assert_equal "chromaticli #{version}", shell_output("#{bin}/chromaticli --version").strip
    assert_match "dark-violet", shell_output("#{bin}/chromaticli list")

    (testpath/".zshrc").write "# existing zsh configuration\n"
    (testpath/".bash_profile").write "# existing bash configuration\n"
    (testpath/".bashrc").write "# existing non-login bash configuration\n"
    %w[zsh bash fish].each do |shell|
      system bin/"chromaticli", "install", "--shell", shell
    end
    assert_match "#{opt_libexec}/hook.zsh", (testpath/".zshrc").read
    assert_match "#{opt_libexec}/hook.bash", (testpath/".bash_profile").read
    assert_match "#{opt_libexec}/hook.bash", (testpath/".bashrc").read
    assert_match "#{opt_libexec}/hook.fish", (testpath/".config/fish/conf.d/chromaticli.fish").read
    assert_equal vsix.to_s, (testpath/"code-state").read.strip
    refute_path_exists testpath/".local/bin/chromaticli"
    refute_path_exists testpath/".config/chromaticli"

    system bin/"chromaticli", "uninstall"
    assert_equal "# existing zsh configuration\n", (testpath/".zshrc").read
    assert_equal "# existing bash configuration\n", (testpath/".bash_profile").read
    assert_equal "# existing non-login bash configuration\n", (testpath/".bashrc").read
    refute_path_exists testpath/".config/fish/conf.d/chromaticli.fish"
    assert_match "dark-violet", shell_output("#{bin}/chromaticli list")
  end
end
