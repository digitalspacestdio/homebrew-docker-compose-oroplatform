class DockerComposeOroplatform < Formula
  desc "CLI tool to run ORO applications locally or on a server"
  homepage "https://github.com/digitalspacestdio/homebrew-docker-compose-oroplatform"
  url "file:///dev/null"
  version "1.2.9"
  sha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

  def self.aliases
    ["orodc"]
  end

  depends_on "coreutils"
  depends_on "jq"
  depends_on "mutagen-io/mutagen/mutagen" if OS.mac?
  depends_on "rsync"
  depends_on "yq"

  def install
    # Install from tap directory instead of downloading from git
    tap_root = Pathname(__FILE__).dirname.parent

    # Copy orodc-sync if exists
    if (tap_root/"bin/orodc-sync").exist?
      (libexec/"orodc-sync").write (tap_root/"bin/orodc-sync").read
      (libexec/"orodc-sync").chmod 0755
    end

    # Copy orodc-find_free_port
    (libexec/"orodc-find_free_port").write (tap_root/"bin/orodc-find_free_port").read
    (libexec/"orodc-find_free_port").chmod 0755

    # Copy entire libexec/orodc/ modular structure (includes all modules and main script)
    if (tap_root/"libexec/orodc").exist?
      cp_r (tap_root/"libexec/orodc"), libexec
    end

    # Copy main orodc dispatcher script to libexec root for backward compatibility
    (libexec/"orodc-main").write (tap_root/"bin/orodc").read
    (libexec/"orodc-main").chmod 0755

    # Create bin symlink to the main dispatcher (no wrapper, direct symlink)
    bin.install_symlink libexec/"orodc-main" => "orodc"
    bin.install_symlink libexec/"orodc-find_free_port" => "orodc-find_free_port"

    # Copy compose directory recursively
    pkgshare.mkpath
    cp_r (tap_root/"compose"), pkgshare
  end

  def caveats
    <<~EOS
      docker-compose-oroplatform was installed
    EOS
  end

  test do
    system "#{bin}/orodc", "--help"
  end
end
