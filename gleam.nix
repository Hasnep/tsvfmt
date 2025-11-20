{
  lib,
  newScope,
  beamPackages,
  buildGleam,
  fetchgit,
}:

let
  inherit (beamPackages) buildMix buildRebar3 fetchHex;
in

lib.makeScope newScope (self: {
  argv = buildGleam {
    name = "argv";
    version = "1.0.2";
    otpApplication = "argv";

    src = fetchHex {
      pkg = "argv";
      version = "1.0.2";
      sha256 = "sha256-uh/wkpUl3roc5nJW5a33enzd/nKePj9Xpb3KoDHe0J0=";
    };
  };

  clip = buildGleam {
    name = "clip";
    version = "1.0.0";
    otpApplication = "clip";

    src = fetchHex {
      pkg = "clip";
      version = "1.0.0";
      sha256 = "sha256-ZpvqI9Bn+JsnSg6GlTPS7HwNsbXmUKA0OcRVh0mUXpQ=";
    };

    beamDeps = with self; [
      gleam_stdlib
    ];
  };

  filepath = buildGleam {
    name = "filepath";
    version = "1.1.2";
    otpApplication = "filepath";

    src = fetchHex {
      pkg = "filepath";
      version = "1.1.2";
      sha256 = "sha256-sGqa8L8Q5RQB1kuY5LYn8dLkjBVJZ9p69NCRR4Cm1Ao=";
    };

    beamDeps = with self; [
      gleam_stdlib
    ];
  };

  gleam_stdlib = buildGleam {
    name = "gleam_stdlib";
    version = "0.65.0";
    otpApplication = "gleam_stdlib";

    src = fetchHex {
      pkg = "gleam_stdlib";
      version = "0.65.0";
      sha256 = "sha256-fGnHHYxJOuEaUYSCincRDrBad4br+LJbNqcvh5w+4Qc=";
    };
  };

  gleam_yielder = buildGleam {
    name = "gleam_yielder";
    version = "1.1.0";
    otpApplication = "gleam_yielder";

    src = fetchHex {
      pkg = "gleam_yielder";
      version = "1.1.0";
      sha256 = "sha256-jk5Oz6eYKFn0MMV/VJIAx3SYI8EGdZ9KGaeK6maHcXo=";
    };

    beamDeps = with self; [
      gleam_stdlib
    ];
  };

  gleave = buildGleam {
    name = "gleave";
    version = "1.0.0";
    otpApplication = "gleave";

    src = fetchHex {
      pkg = "gleave";
      version = "1.0.0";
      sha256 = "sha256-6+sN+cdkpssiYj/28DoLyXjXUiUwPzu97rcFot1wDQ0=";
    };
  };

  gleeunit = buildGleam {
    name = "gleeunit";
    version = "1.6.1";
    otpApplication = "gleeunit";

    src = fetchHex {
      pkg = "gleeunit";
      version = "1.6.1";
      sha256 = "sha256-/caKjEkrHptCkkkGLNm6ybVTjG+/WEgXIF0JmMQuHaw=";
    };

    beamDeps = with self; [
      gleam_stdlib
    ];
  };

  simplifile = buildGleam {
    name = "simplifile";
    version = "2.3.0";
    otpApplication = "simplifile";

    src = fetchHex {
      pkg = "simplifile";
      version = "2.3.0";
      sha256 = "sha256-CoaNrGBj2emDR3mBg5gQ3C5VMoWrRYi4fj6clqf7TLQ=";
    };

    beamDeps = with self; [
      filepath
      gleam_stdlib
    ];
  };

  stdin = buildGleam {
    name = "stdin";
    version = "2.0.2";
    otpApplication = "stdin";

    src = fetchHex {
      pkg = "stdin";
      version = "2.0.2";
      sha256 = "sha256-Q3CEk5zglOBtMtB+sZt0Rz0IiVq4F8A1UM7f2/Df3Bk=";
    };

    beamDeps = with self; [
      gleam_stdlib
      gleam_yielder
    ];
  };

  string_width = buildGleam {
    name = "string_width";
    version = "3.3.1";
    otpApplication = "string_width";

    src = fetchHex {
      pkg = "string_width";
      version = "3.3.1";
      sha256 = "sha256-ii6C7Qg+VniaRTyGkNG30aSOP5TceP+v6n6FpOgBwpE=";
    };

    beamDeps = with self; [
      gleam_stdlib
    ];
  };
})
