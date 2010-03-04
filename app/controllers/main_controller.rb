require 'net/http'
require 'gettext_rails'

class MainController < ApplicationController

  verify :only => :ymp, :params => [:project, :repository, :arch, :binary],
    :redirect_to => :index

  # these pages are completely static:
  caches_page :release, :download_js

  def ymp_with_arch_and_version
    path = "/published/#{params[:project]}/#{params[:repository]}/#{params[:arch]}/#{params[:binary]}?view=ymp"
    res = get_from_api(path)
    render :text => res.body, :content_type => res.content_type
  end

  def ymp_without_arch_and_version
    path = "/published/#{params[:project]}/#{params[:repository]}/#{params[:package]}?view=ymp"
    res = get_from_api(path)
    render :text => res.body, :content_type => res.content_type
  end

  def set_release(release)
    if release == "111"
       @isos = {}
       @directory = "http://download.opensuse.org/distribution/11.1"
       @isos["lang-32"] = "11.1-Addon-Lang-i586"
       @isos["lang-64"] = "11.1-Addon-Lang-x86_64"
       @isos["nonoss"] = "11.1-Addon-NonOss-BiArch-i586-x86_64"
       @isos["kde-64"] = "11.1-KDE4-LiveCD-x86_64"
       @isos["kde-32"] = "11.1-KDE4-LiveCD-i686"
       @isos["gnome-64"] = "11.1-GNOME-LiveCD-x86_64"
       @isos["gnome-32"] = "11.1-GNOME-LiveCD-i686"
       @isos["dvd-64"] = "11.1-DVD-x86_64"
       @isos["dvd-32"] = "11.1-DVD-i586"
       @isos["net-32"] = "11.1-NET-i586"
       @isos["net-64"] = "11.1-NET-x86_64"

       @releasenotes = "http://www.suse.de/relnotes/i386/openSUSE/11.1/RELEASE-NOTES.en.html"
       @releasename = "openSUSE 11.1"
       @repourl = "http://download.opensuse.org/distribution/11.1"
       @medium = "dvd"
    elsif release == "112"
       @isos = {}
       @directory = "http://download.opensuse.org/distribution/11.2"
       @isos["lang-32"] = "11.2-Addon-Lang-i586"
       @isos["lang-64"] = "11.2-Addon-Lang-x86_64"
       @isos["nonoss"] = "11.2-Addon-NonOss-BiArch-i586-x86_64"
       @isos["kde-64"] = "11.2-KDE4-LiveCD-x86_64"
       @isos["kde-32"] = "11.2-KDE4-LiveCD-i686"
       @isos["gnome-64"] = "11.2-GNOME-LiveCD-x86_64"
       @isos["gnome-32"] = "11.2-GNOME-LiveCD-i686"
       @isos["dvd-64"] = "11.2-DVD-x86_64"
       @isos["dvd-32"] = "11.2-DVD-i586"
       @isos["net-32"] = "11.2-NET-i586"
       @isos["net-64"] = "11.2-NET-x86_64"

       @releasenotes = "http://www.suse.de/relnotes/i386/openSUSE/11.2/RELEASE-NOTES.en.html"
       @releasename = "openSUSE 11.2"
       @repourl = "http://download.opensuse.org/distribution/11.2"
       @medium = "dvd"
    elsif release == "developer"
       @isos = {}
       @directory = "http://download.opensuse.org/distribution/11.3-Milestone3"
       @isos["lang-32"] = "Addon-Lang-Build0476-i586"
       @isos["lang-64"] = "Addon-Lang-Build0476-x86_64"
       @isos["nonoss"] = "Addon-NonOss-BiArch-Build0476-i586-x86_64"
       @isos["kde-64"] = "KDE-LiveCD-Build0476-x86_64"
       @isos["kde-32"] = "KDE-LiveCD-Build0476-i686"
       @isos["gnome-64"] = "GNOME-LiveCD-Build0476-x86_64"
       @isos["gnome-32"] = "GNOME-LiveCD-Build0476-i686"
       @isos["dvd-64"] = "DVD-Build0475-x86_64"
       @isos["dvd-32"] = "DVD-Build0475-i586"
       @isos["net-32"] = "NET-Build0475-i586"
       @isos["net-64"] = "NET-Build0475-x86_64"

       @releasenotes = "http://www.suse.de/relnotes/i386/openSUSE/11.3/RELEASE-NOTES.en.html"
       @releasename = "openSUSE 11.3-Milestone3"
       @repourl = "http://download.opensuse.org/distribution/11.3"
       @medium = "dvd"
    end
    @release = release
  end

  def redirectit(release)
    if params[:lang].nil?
      lang = request.compatible_language_from(LANGUAGES) || "en"
    else
      lang = params[:lang][0]
    end
    notice = nil
    url = "/%s/%s" % [release, lang]
    if request.user_agent && request.user_agent.index('Mozilla/5.0 (compatible; Konqueror/3')
	notice = _("Konqueror of KDE 3 is unfortunately unmaintained and its javascript implementation contains bugs that make it impossible to use with this page. Please make sure you have javascript disabled before you <a href='%s'>continue</a>.") % url
    end
    if notice
       render :template => "main/redirect_with_notice", :locals => { :notice => notice }
    else
       redirect_to url
    end
  end

  def developer
    redirectit("developer")
    #redirect_to "http://en.opensuse.org/Factory"
  end
   
  def index
    redirectit("112")
  end

  def release
    @lang = params[:lang][0].gsub(/\-/, '_')
    GetText.locale = @lang

    set_release(params[:release])
    render :template => "main/release"
  end

  def change_install
    set_release(params[:release])
    @medium = params[:medium]
    @lang = params[:lang]
    render :template => "main/release"
  end

  def download_js
    set_release(params[:release])
    render :template => "main/download", :content_type => 'text/javascript', :layout => false
  end

  def show_request
    render :template => "main/testrequest", :layout => false
  end

  def download
    set_release(params[:release])
    medium = params[:medium]

    if params[:arch] == "i686"
      medium += "-32"
    else
      medium += "-64"
    end

    suffix = ".iso"
    
    case
    when params[:protocol] == "torrent"
      if params[:medium] != "net"
          suffix = ".iso.torrent"
      end
    when params[:protocol] == "mirror"
      suffix = ".iso?mirrorlist"
    when params[:protocol] == "metalink"
      suffix = ".iso.metalink"
    end
    redirect_to @directory + "/iso/openSUSE-" + @isos[medium] + suffix

  end

  private
  
  def get_from_api(path)
    req = Net::HTTP::Get.new(path)
    req['x-username'] = "obs_read_only"

    host, port = API_HOST.split(/:/)
    port ||= 80
    res = Net::HTTP.new(host, port).start do |http|
      http.request(req)
    end
  end
end
