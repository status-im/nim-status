import ../../nim_status/lib/account
import stew/[results]
import secp256k1

let seed = getSeed(Mnemonic "panda eyebrow bullet gorilla call smoke muffin taste mesh discover soft ostrich alcohol speed nation flash devote level hobby quick inner drive ghost inside")

assert $(derive(seed, KeyPath "m/44'/60'/0'/0/0").get()) == "ff1e68eb7bf2f48651c47ef0177eb815857322257c5894bb4cfd1176c9989314"
