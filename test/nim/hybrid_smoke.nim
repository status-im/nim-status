import ../../nim_status/go/shim as go_shim
import ../../nim_status/hybrid/shim as hybrid

const chatKey = "0x04e3b648524ca528588527ff8ea71d8b60e43bbd85f7983fa5f12b3fa27446e66f46c7c88329b2229cfbef3daa5fc6b65a385eac405c610ec285a21a5fd4034690"

echo hybrid.generateAlias(chatKey)
echo go_shim.generateAlias(chatKey)

echo hybrid.hashMessage("test")
echo go_shim.hashMessage("test")

# the base64 encodings are not expected to match though visually re: pixels and
# colors they're an exact match
echo hybrid.identicon(chatKey)
echo go_shim.identicon(chatKey)
