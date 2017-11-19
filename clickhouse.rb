class Clickhouse < Formula
  desc "is an open-source column-oriented database management system."
  homepage "https://clickhouse.yandex/"
  url "https://github.com/yandex/ClickHouse/archive/v1.1.54284-stable.zip"
  version "1.1.54284"
  sha256 "2985575609980d94bb75d67a20880e3a6c09490fe0f65b31ae130b9c451560da"

  devel do
    url "https://github.com/yandex/ClickHouse/archive/v1.1.54288-testing.zip"
    version "1.1.54214"
    sha256 "44c0aa152a9c0c4b99e17bba55a69d839d1a12c0346679eb681508eba9896ad2"
  end

  bottle do
    rebuild 1
    root_url 'https://github.com/deem0n/homebrew-clickhouse/releases/download/v1.1.54284'
    sha256 "4a35a4c2cb2c9e4066a30be79e250428ee98c1f0c5aacbae4a9470e9dc9f2fb9" => :sierra
  end

  head "https://github.com/yandex/ClickHouse.git"

  depends_on "cmake" => :build
  depends_on "gcc@6" => :build

  depends_on "boost" => :build
  depends_on "icu4c" => :build
  depends_on "mysql" => :build
  depends_on "openssl" => :build
  depends_on "unixodbc" => :build
  depends_on "libtool" => :build
  depends_on "gettext" => :build
  depends_on "zlib" => :build
  depends_on "readline" => :recommended

  def install
    ENV["ENABLE_MONGODB"] = "0"
    #ENV["ENABLE_MYSQL"] = "1"
    ENV["CC"] = "#{Formula["gcc@6"].bin}/gcc-6"
    ENV["CXX"] = "#{Formula["gcc@6"].bin}/g++-6"
    ENV["CFLAGS"] = "-I/usr/local/include"
    ENV["CXXFLAGS"] = "-I/usr/local/include"
    ENV["LDFLAGS"] = "-L/usr/local/lib"

    cmake_args = %w[]
    cmake_args << "-DUSE_STATIC_LIBRARIES=0" if MacOS.version >= :sierra
    cmake_args << "-DENABLE_MYSQL=1"

    mkdir "build"
    cd "build" do
      system "cmake", "..", *cmake_args
      system "make"
      if MacOS.version >= :sierra
        lib.install Dir["#{buildpath}/build/dbms/*.dylib"]
        lib.install Dir["#{buildpath}/build/contrib/libzlib-ng/*.dylib"]
      end
      bin.install "#{buildpath}/build/dbms/src/Server/clickhouse"
      bin.install_symlink "clickhouse" => "clickhouse-server"
      bin.install_symlink "clickhouse" => "clickhouse-client"
    end

    mkdir "#{var}/clickhouse"

    inreplace "#{buildpath}/dbms/src/Server/config.xml" do |s|
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
    (etc/"clickhouse-server").install "#{buildpath}/dbms/src/Server/config.xml"
    (etc/"clickhouse-server").install "#{buildpath}/dbms/src/Server/users.xml"
  end

  def plist; <<-EOS.undent
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

  def caveats; <<-EOS.undent
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
    system "#{bin}/clickhouse-client", "--version"
  end
end
