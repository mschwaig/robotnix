{ config, lib, ... }:
with lib;
let
  # https://source.android.com/setup/start/build-numbers
  # TODO: Make an autoupdate script too.
  release = rec {
    marlin = {
      "9" = {
        tag = "android-9.0.0_r46"; # PQ3A.190801.002
        sha256 = "08hjjmyrr4isb1hl3wixyysp9792bh2pp0ifh9w9p5v90nx7s1sz";
      };
      "10" = {
        tag = "android-10.0.0_r2"; # QP1A.190711.20
        sha256 = "11pmxdrps2n8im4wl9vi6pq4a16gl55g9y3kd2kn8n5rz61h2vrb";
      };
    };
    taimen = marlin;
    crosshatch = marlin;
    bonito = {
      "9" = {
        tag = "android-9.0.0_r47"; # PQ3B.190801.002
        sha256 = "0wqcy2708i8znr3xqkmafrk5dvf9z222f3705j3l2jdb67aqim49";
      };
      "10" = marlin."10";
    };
  }.${config.deviceFamily}.${config.androidVersion};
  kernelTag = {
    "9" = {
      marlin = "android-9.0.0_r0.111";
      taimen = "android-9.0.0_r0.112";
      crosshatch = "android-9.0.0_r0.113";
      bonito = "android-9.0.0_r0.114";
    };
    "10" = {
      marlin = "android-10.0.0_r0.1";
      taimen = "android-10.0.0_r0.2";
      crosshatch = "android-10.0.0_r0.3";
      bonito = "android-10.0.0_r0.4";
    };
  }.${config.androidVersion}.${config.deviceFamily};
  deviceDirName = if (config.device == "walleye") then "muskie" else config.deviceFamily;
in
mkIf (config.flavor == "vanilla") {
  source.manifest = {
    url = mkDefault "https://android.googlesource.com/platform/manifest"; # I get 100% cpu usage and no progress with this URL. Needs older curl version
    rev = mkDefault "refs/tags/${release.tag}";
    sha256 = mkDefault release.sha256;
  };

  # TODO: Only build kernel for marlin since it needs verity key in build.
  # Kernel sources for crosshatch and bonito require multiple repos--which
  # could normally be fetched with repo at https://android.googlesource.com/kernel/manifest
  # but google didn't push a branch like android-msm-crosshatch-4.9-pie-qpr3 to that repo.
  kernel.useCustom = mkDefault (config.signBuild && (config.deviceFamily == "marlin"));
  kernel.src = builtins.fetchGit {
    url = "https://android.googlesource.com/kernel/msm";
    ref = "refs/tags/${kernelTag}";
  };

  removedProductPackages = [ "webview" "Browser2" "QuickSearchBox" ];
  source.dirs."external/chromium-webview".enable = false;
  source.dirs."packages/apps/QuickSearchBox".enable = false;
  source.dirs."packages/apps/Browser2".enable = false;

  source.patches = [ (../patches + "/${config.androidVersion}" + /disable-quicksearch.patch) ];
  source.dirs."device/google/${deviceDirName}".patches = [
    (../patches + "/${config.androidVersion}/${deviceDirName}-fix-device-names.patch")
  ];

  resources."frameworks/base/core/res".config_swipe_up_gesture_setting_available = true; # enable swipe up gesture functionality as option
}
