class Clickhouse < Formula
  target_version = "19.17.5.18"
  desc "is an open-source column-oriented database management system."
  homepage "https://clickhouse.yandex/"
  version "#{target_version}-stable"
  url "https://github.com/ClickHouse/ClickHouse.git", :using => :git, :tag => "v#{version}"
  sha256 "0895c24e2d10b46f2c0eb391797aeac342b39a89fb4350efdaa1601d0b1e50a6"

  devel do
    target_version = "19.19.1.1902"
    version "#{target_version}-testing"
    url "https://github.com/ClickHouse/ClickHouse.git", :using => :git, :tag => "v#{version}"
    sha256 "44c0aa152a9c0c4b99e17bba55a69d839d1a12c0346679eb681508eba9896ad2"
  end

  # --HEAD
  head "https://github.com/ClickHouse/ClickHouse.git", :using => :git, :tag => "v19.19.1.1902-testing"

  bottle do
    rebuild 1
    root_url "https://github.com/deem0n/homebrew-clickhouse/releases/download/v#{target_version}/"
    sha256 "f9f871f85761bfbe6ea9338746b11e73398a95256da4c59dc50b4a8170bf2c9d" => :mojave
  end

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  #depends_on "mariadb" => :build


#  depends_on "boost" => :build
#  depends_on "icu4c" => :build
#  depends_on "mysql" => :build
#  depends_on "openssl" => :build
#  depends_on "unixodbc" => :build
#  depends_on "libtool" => :build
#  depends_on "gettext" => :build
#  depends_on "zlib" => :build
#  depends_on "readline" => :recommended

  def install
    ENV["ENABLE_MONGODB"] = "0"
    #ENV["LDFLAGS"] = "-all_load"


    #ENV["ENABLE_MYSQL"] = "1"
    #ENV["CC"] = "#{Formula["gcc"].bin}/gcc-9"
    #ENV["CXX"] = "#{Formula["gcc"].bin}/g++-9"
    #ENV["CFLAGS"] = "-I/usr/local/include"
    #ENV["CXXFLAGS"] = "-I/usr/local/include"
    #ENV["LDFLAGS"] = "-L/usr/local/lib"

    cmake_args = %w[]
    cmake_args << "-DUSE_STATIC_LIBRARIES=1" if MacOS.version >= :sierra
    cmake_args << "-DENABLE_MYSQL=0"
    cmake_args << "-DENABLE_IPO=0" # WE have -- IPO/LTO not enabled.
    # cmake_args << "-DLLVM_ENABLE_LTO=Thin" # ????

    mkdir "build"
    # boost somehow is not populated with standard git commands, do manual forced fetch!
    system "git", "submodule", "update", "--init", "--recursive", "--force", "contrib/boost"
    cd "build" do
      system "cmake", "..", *cmake_args
      system "ninja"
      if MacOS.version >= :sierra
        #lib.install Dir["#{buildpath}/build/dbms/*.dylib"]
        #lib.install Dir["#{buildpath}/build/contrib/libzlib-ng/*.dylib"]
      end
      bin.install "#{buildpath}/build/dbms/programs/clickhouse"
      bin.install_symlink "clickhouse" => "clickhouse-server"
      bin.install_symlink "clickhouse" => "clickhouse-client"
    end

    mkdir "#{var}/clickhouse"

    inreplace "#{buildpath}/dbms/programs/server/config.xml" do |s|
      s.gsub! "/var/lib/clickhouse/", "#{var}/clickhouse/"
      s.gsub! "/var/log/clickhouse-server/", "#{var}/log/clickhouse/"
      s.gsub! "<!-- <max_open_files>262144</max_open_files> -->", "<max_open_files>262144</max_open_files>"
    end

    # Copy configuration files
    mkdir "#{etc}/clickhouse-client/"
    mkdir "#{etc}/clickhouse-server/"
    mkdir "#{etc}/clickhouse-server/config.d/"
    mkdir "#{etc}/clickhouse-server/users.d/"

    #there is no client config as of Sept 2017
    #(etc/"clickhouse-client").install "#{buildpath}/dbms/src/Client/config.xml"
    (etc/"clickhouse-server").install "#{buildpath}/dbms/programs/server/config.xml"
    (etc/"clickhouse-server").install "#{buildpath}/dbms/programs/server/users.xml"
  end

  def plist; <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <false/>
        <key>ProgramArguments</key>
        <array>
            <string>#{opt_bin}/clickhouse-server</string>
            <string>--config-file</string>
            <string>#{etc}/clickhouse-server/config.xml</string>
        </array>
        <key>WorkingDirectory</key>
        <string>#{HOMEBREW_PREFIX}</string>
      </dict>
    </plist>
    EOS
  end

  def caveats; <<-EOS
    The configuration files are available at:
      #{etc}/clickhouse-client/
      #{etc}/clickhouse-server/
    The database itself will store data at:
      #{var}/clickhouse/

    If you're going to run the server, make sure to increase `maxfiles` limit:
      https://github.com/yandex/ClickHouse/blob/master/MacOS.md
  EOS
  end

  test do
    assert_equal "ClickHouse client version #{target_version}.", shell_output("#{bin}/clickhouse-client --version").strip
    assert_equal "ClickHouse server version #{target_version}.", shell_output("#{bin}/clickhouse-server --version").strip
  end
end
