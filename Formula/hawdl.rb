class Hawdl < Formula
  desc "Keep macOS awdl0 down so AWDL stops stealing Wi-Fi airtime"
  homepage "https://github.com/taross-f/hawdl"
  license "MIT"
  head "https://github.com/taross-f/hawdl.git", branch: "main"

  # Head-only until the first tagged release:
  #
  #   brew install --HEAD taross-f/hawdl/hawdl
  #
  # Tagging publishes a release whose notes carry the exact stanza to paste in
  # here, checksum included, so this does not need computing by hand:
  #
  #   url "https://github.com/taross-f/hawdl/archive/refs/tags/v0.1.0.tar.gz"
  #   sha256 "..."

  depends_on xcode: ["15.0", :build]
  depends_on macos: :sonoma

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"

    bin.install ".build/release/hawdld"
    bin.install ".build/release/hawdl"

    # SwiftPM emits a bare executable; assemble the .app bundle here so the
    # menu bar extra gets LSUIElement and a bundle identifier.
    app = prefix/"HawdlBar.app"
    (app/"Contents/MacOS").mkpath
    (app/"Contents/MacOS").install ".build/release/HawdlBar"
    (app/"Contents").install "Sources/HawdlBar/Resources/Info.plist"

    # swift build ad-hoc signs the bare executable, and adding Info.plist
    # afterwards changes the bundle out from under that signature. macOS then
    # refuses to launch it, silently: no error, and no menu bar item.
    system "codesign", "--force", "--deep", "--sign", "-", app
  end

  service do
    run [opt_bin/"hawdld"]
    require_root true
    keep_alive true
    run_type :immediate
    log_path var/"log/hawdld.log"
    error_log_path var/"log/hawdld.err.log"
  end

  def caveats
    <<~EOS
      hawdld needs root to change interface flags, so start it with sudo:

        sudo brew services start hawdl

      Without it, `hawdl` and HawdlBar have nothing to talk to.

      The menu bar app is not installed into /Applications automatically.
      Link it yourself if you want it in Launchpad and in the login items UI:

        ln -sfn #{opt_prefix}/HawdlBar.app /Applications/HawdlBar.app
        open /Applications/HawdlBar.app

      Holding awdl0 down disables AirDrop, Handoff, Sidecar, Universal Control
      and Continuity Camera. Toggle it back with `hawdl release` or from the
      menu bar when you need them.

      The control socket at /var/run/hawdl.sock is mode 0666: any local user on
      this machine can toggle awdl0. See the README.
    EOS
  end

  test do
    assert_match(/^hawdl \d+\.\d+\.\d+$/, shell_output("#{bin}/hawdl --version").strip)
    assert_match(/^hawdld \d+\.\d+\.\d+$/, shell_output("#{bin}/hawdld --version").strip)

    # An unlaunchable bundle fails silently at runtime, so catch it here.
    system "codesign", "--verify", "--deep", "--strict", prefix/"HawdlBar.app"

    # The daemon must come up, serve the protocol and shut down cleanly without
    # root, using a simulated interface.
    socket = (testpath/"hawdl.sock").to_s
    state = (testpath/"state.json").to_s
    pid = spawn (bin/"hawdld").to_s, "--dry-run", "--socket", socket, "--state", state
    begin
      sleep 1
      assert_match "\"desired\"", shell_output("#{bin}/hawdl status --socket #{socket} --json")
    ensure
      Process.kill "TERM", pid
      Process.wait pid
    end
  end
end
