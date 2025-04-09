require 'formula'

class DockerComposeOroplatform < Formula
  url "https://github.com/digitalspacestdio/homebrew-docker-compose-oroplatform.git", :using => :git
  version "0.6.0"
  revision 5

  depends_on 'coreutils'
  depends_on 'rsync'
  depends_on 'mutagen-io/mutagen/mutagen' if OS.mac?

  def install
    libexec.install "bin/dc-oro"
    bin.write_exec_script libexec/"dc-oro"

    pkgshare.install "compose"
  end

  # def post_install
  #   dc_oro_compose = var/"lib/dc-oro/compose"
  #   dc_oro_docker = var/"lib/dc-oro/docker"
    
  #   rm_rf dc_oro_compose if dc_oro_compose.exist?
  #   rm_rf dc_oro_docker if dc_oro_docker.exist?
  
  #   (dc_oro_compose).mkpath
  #   (dc_oro_docker).mkpath
  
  #   cp_r "#{buildpath}/compose", dc_oro_compose
  #   cp_r "#{buildpath}/docker", dc_oro_docker
  # end

  def caveats
    s = <<~EOS
      docker-compose-oroplatform was installed
    EOS
    s
  end
end
