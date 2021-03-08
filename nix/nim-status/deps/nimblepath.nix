{ pkgs, stdenv, lib, fetchFromGitHub
# Dependencies
, xcodeWrapper
, writeScript
, androidPkgs
, newScope
, git 
, platform ? "android"
, arch ? "386"
, api ? "23" } :



let
  nimble-deps = {
    chroma = {
      url = "https://github.com/treeform/chroma.git";
      rev = "b5947286cba4f08162376090582e4043cfc96a37";
      sha256 = "11c77ccivv9nqc5g1cfrhm02fncr6i1w2xffk3w6b18ijl9a53rv";
    };

    news = {
      url = "https://github.com/tormund/news.git";
      rev = "a3a6e3ae5ff16126942f4febe746ca4da978072b";
      sha256 = "0qmwh2p306z2rxmwlfqfj8b3j92bdwavxa8z6jifmak5n0inn8ad";
    };

    nim-bearssl = {
      url = "https://github.com/status-im/nim-bearssl.git";
      rev = "33b2303fc3b64359970b77bb09274c3e012ff37f";
      sha256 = "0ynjiwxpacn98ab8nw6vv53482ji685wymdslnws6qibyvvfkb0b";
    };

    nim-byteutils = {
      url = "https://github.com/status-im/nim-byteutils.git";
      rev = "69ce66ef434b03cf8938be8aa5c658982aeccb40";
      sha256 = "1lkg6h4xi7rwggwq1rhf5y23jlb882k9gbjhh48wqz1d4rzkg8g1";
    };

    nim-chronicles = {
      url = "https://github.com/status-im/nim-chronicles.git";
      rev = "b9a7c6bb0733ce8c76f0ac8c7889c5e48e7c924f";
      sha256 = "1vhz02pfdpbfsmh5v83d0jar3gn6y2bkndni1v4xr3ms8sjnc8lh";
    };

    nim-chronos = {
      url = "https://github.com/status-im/nim-chronos.git";
      rev = "483054cda6e8fd68d0af56edf5bdf59e9b7b3ce8";
      sha256 = "1cdq4gc8cr70ca8lnp0cic2bla840adqis6623xb2bgxmpgr4mim";
    };

    nim-confutils = {
      url = "https://github.com/status-im/nim-confutils.git";
      rev = "39456fa3d5b637053b616e50a8350b2b932a1d4c";
      sha256 = "1pc2s35jaf3ny8l4w88779c0ariy1fbd06bgkqgyirr830f304xb";
    };

    nim-eth = {
      url = "https://github.com/status-im/nim-eth.git";
      rev = "765883c454be726799f4e724b4dc2ca8fe25bc74";
      sha256 = "1088jjc5rv57xskr4ylwgpgnfcsvy0gy2d92amhk1rbhwv56m6gd";
    };

    nim-faststreams = {
      url = "https://github.com/status-im/nim-faststreams.git";
      rev = "5df69fc6961e58205189cd92ae2477769fa8c4c0";
      sha256 = "1w0k94sf6rr4dj9028aj5wg8f8qyc5n1xqlzi37rkkf02vsay798";
    };

    nim-http-utils = {
      url = "https://github.com/status-im/nim-http-utils.git";
      rev = "33d70b9f378591e074838d6608a4468940137357";
      sha256 = "02zbjixrx26nxdbhmvykji0b2immc3z2d0dmky4b454ldsn88s4x";
    };

    nim-json-rpc = {
      url = "https://github.com/status-im/nim-json-rpc.git";
      rev = "244254632b15c745b6e15537aafd401f360d9928";
      sha256 = "1nj3111ni42jfnvnhffzpd1fv0s1362rr8n6rgxcqq26gsivcgks";
    };

    nim-json-serialization = {
      url = "https://github.com/status-im/nim-json-serialization.git";
      rev = "3b0c9eafa4eb75c6257ec5cd08cf6d25c31119a6";
      sha256 = "0q0f5d3bi9868wsl2rbwi52pwq0vyzdkdmcpvfq6qxp703zx6al6";
    };

    nim-libbacktrace = {
      url = "https://github.com/status-im/nim-libbacktrace.git";
      rev = "dc2c199d41dc90de75043d1ee4efe5e0323932bf";
      sha256 = "1y9il7ylgx752kd3mvhs106mn1m0fb54m7rm8r3r76r4qjk8f21v";
    };

    nim-libp2p = {
      url = "https://github.com/status-im/nim-libp2p.git";
      rev = "556213abf4bcfb33e27d28e5148619343df05dbb";
      sha256 = "031i3vj9xsbzbb3k5wqzvcv4nbmhy57670y63zb0fw2x5v3p6fvd";
    };

    nim-metrics = {
      url = "https://github.com/status-im/nim-metrics.git";
      rev = "f91deb74228ecb14fb82575e4d0f387ad9732b8a";
      sha256 = "1ygvpg8pzjbnp86w6r5v9pv972xzpaw1m5fm1bw1v9c5nxlqcf7h";
    };

    nim-normalize = {
      url = "https://github.com/nitely/nim-normalize.git";
      rev = "db9a74ad6a301f991c477fc2d90894957f640654";
      sha256 = "059m4i5i5ng2il4fhkfbvqwyh6j8a93p9pydgilgcj0p34i6c3y4";
    };

    nim-result = {
      url = "https://github.com/arnetheduck/nim-result";
      rev = "2fcb3de80bfcfeb6f02ed441e464ca1adb4e40fc";
      sha256 = "10xkzqhmamix09n1b42pbng2hja0p1v40ij7gykd2ggvi25p4z6h";
    };

    nim-secp256k1 = {
      url = "https://github.com/status-im/nim-secp256k1.git";
      rev = "a9d5cba699a0ee636ad155ea0dc49747b24d2ea4";
      sha256 = "18q3j34slsr8hfxlrywapvkf9sv0mxam27h676l9hpck9yfgg4gm";
    };


    nim-serialization = {
      url = "https://github.com/status-im/nim-serialization.git";
      rev = "474bdbf49cf1634ba504888ad1a1927a2703bd3f";
      sha256 = "0aw3rcwpby7rbxrf59yp80bcsd7k0nil2iw1ryxr6wdzfkfiw1h3";
    };

    nim-sqlcipher = {
      url = "https://github.com/status-im/nim-sqlcipher";
      rev = "d4fa3f0444938001ae7601a363de88f8571b2067";
      sha256 = "1yaj6h1wphdbysh6m0cwqv94dfylr6dzysvnxyf6421mfdkgpazr";
    };

    nim-stew = {
      url = "https://github.com/status-im/nim-stew";
      rev = "ff524ed832b9933760a5c500252323ec840951a6";
      sha256 = "092cyzpcxjj3ldlfdi39z9h13wsv1q0pcgpwvq0r93n63adzi71f";
    };

    nim-stint = {
      url = "https://github.com/status-im/nim-stint";
      rev = "9e49b00148884a01d61478ae5d2c69b543b93ceb";
      sha256 = "0dkszdnp3sji290mg18i0nnalnks7jfry4x55dfyhfc7ad054kqc";
    };

    nim-unicodedb = {
      url = "https://github.com/nitely/nim-unicodedb";
      rev = "7c6ee4bfc184d7121896a098d68b639a96df7af1";
      sha256 = "06j8d0bjbpv1iibqlmrac4qb61ggv17hvh6nv4pbccqk1rlpxhsq";
    };

    nim-waku = {
      url = "https://github.com/status-im/nim-waku";
      rev = "886b458ff55d960761906a8b907e5ce192b5ea61";
      sha256 = "0lvp2khkkf80h3cz6qypyfdk6aw8zikpcf0sh5rqxfxi39kvsz2v";
    };

    nim-web3 = {
      url = "https://github.com/status-im/nim-web3";
      rev = "dde382f70e811d964a000bdd4d86151615f9d4c0";
      sha256 = "1wqy6hpg1brd0r1d4mgrqn8s9z0wq6p9qinpcksj3ljrdqiggcrm";
    };

    nimPNG = {
      url = "https://github.com/status-im/nimPNG";
      rev = "7ff39ec00df29b55b6de0f67d31b8d52eb5c2d8f";
      sha256 = "1cvpdb5h9s7532krk5qycm1q0c9d1aq0pgazxmkfk477n0fcdhwc";
    };

    nimage = {
      url = "https://github.com/Ethosa/nimage";
      rev = "d683a7319c867c6cd1d856b63f407c52ad3e3821";
      sha256 = "0z5hm7wmzxjqm9giiy7d0h5wshjzw2bkhhlnm6krc15wr9kizgig";
    };

    nimcrypto = {
      url = "https://github.com/cheatfate/nimcrypto";
      rev = "a065c1741836462762d18d2fced1fedd46095b02";
      sha256 = "1030yl6y6ymhp5iifpg27cy4kx6jc5mxb76q0pfgb66h9fflpvlj";
    };

    status-go = {
      url = "https://github.com/status-im/status-go";
      rev = "7387049d4b524d3371966fa07ccba3e08b6c652a";
      sha256 = "1x3qalfx832w09fl1ysnpv0a8sqb8q64hjj89wa8k9pf2wcvgg9g";
    };
# 92e5042667b747d22106f085eaa9b5e9766ba474  nimbus-build-system
  };

  fetchedDirs = builtins.map (name:
      let
        dep = nimble-deps.${name};
        src = pkgs.fetchgit {
          url = dep.url;
          rev = dep.rev;
          sha256 = dep.sha256;
          fetchSubmodules = false;
        };
      in stdenv.mkDerivation {
        name = "fetch-nimble-dep-${name}";
        inherit src;
        buildInputs = [ pkgs.coreutils ];
        builder = writeScript "fetch-nimble-dep-builder.sh"
        ''
          source $stdenv/setup

          mkdir $out
          ln -sf $src $out/${name}
        '';
      }
    ) 
    (builtins.attrNames nimble-deps);

in stdenv.mkDerivation {
  name = "nim-status-nimbledeps";

  buildInputs = [ pkgs.coreutils ];

  builder = writeScript "nimbledeps-builder.sh"
  ''
    source $stdenv/setup

    mkdir $out

    for dep in ${lib.concatStringsSep " " fetchedDirs}; do
      echo $dep
      cp -r $dep/* $out/
    done
  '';
}

