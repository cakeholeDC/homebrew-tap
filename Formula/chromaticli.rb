class Chromaticli < Formula
  desc "Sync terminal colors with VSCode workspace themes"
  homepage "https://github.com/cakeholeDC/chromaticli"
  url "https://github.com/cakeholeDC/chromaticli/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "62a2c77ba47bf63a254ff2b03fe0c423b6288f21c1182f7004afe31beb9cdc26"
  license "MIT"

  depends_on "jq"

  def install
    libexec.install "chromaticli", "hook.zsh", "hook.bash", "hook.fish", "themes.json"
    (bin/"chromaticli").write_env_script opt_libexec/"chromaticli", CHROMATICLI_LIBEXEC: opt_libexec
  end

  def caveats
    <<~EOS
      Run `chromaticli install` to configure shell integration, then restart your shell.
      Before removing the formula, run `chromaticli uninstall` to remove shell integration.
    EOS
  end

  test do
    ENV["HOME"] = testpath
    ENV["XDG_CONFIG_HOME"] = testpath/".config"
    ENV["ZDOTDIR"] = testpath

    assert_equal "chromaticli #{version}", shell_output("#{bin}/chromaticli --version").strip
    assert_match "monokai", shell_output("#{bin}/chromaticli list")

    (testpath/".zshrc").write "# existing zsh configuration\n"
    (testpath/".bash_profile").write "# existing bash configuration\n"
    %w[zsh bash fish].each do |shell|
      system bin/"chromaticli", "install", "--shell", shell
    end
    assert_match "#{opt_libexec}/hook.zsh", (testpath/".zshrc").read
    assert_match "#{opt_libexec}/hook.bash", (testpath/".bash_profile").read
    assert_match "#{opt_libexec}/hook.fish", (testpath/".config/fish/conf.d/chromaticli.fish").read
    refute_path_exists testpath/".local/bin/chromaticli"
    refute_path_exists testpath/".config/chromaticli"

    system bin/"chromaticli", "uninstall"
    assert_equal "# existing zsh configuration\n", (testpath/".zshrc").read
    assert_equal "# existing bash configuration\n", (testpath/".bash_profile").read
    refute_path_exists testpath/".config/fish/conf.d/chromaticli.fish"
    assert_match "monokai", shell_output("#{bin}/chromaticli list")
  end
end
