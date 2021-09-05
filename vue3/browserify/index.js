const Buffer = require('buffer/').Buffer
const sigUtil = require('eth-sig-util')

// browserify browserify/index.js -d -p [minifyify --no-map] > public/enc.js

window.base64ToHex = function(rawData) {
  const buffer = Buffer.from(rawData, 'base64');
  return buffer.toString('hex');
}

window.hexToBase64 = function(rawData) {
  const buffer = Buffer.from(rawData, 'hex');
  return buffer.toString('base64');
}

window.hexToUint8Array = function(hex) {
  var res = []
  for (var i = 0; i < hex.length; i += 2) {
    res.push(parseInt(hex.substr(i, 2), 16))
  }
  return Uint8Array.from(res)
}

window.hexToEncObj = function(hex) {
  const lengths = hexToUint8Array(hex.substr(2,6))
  var obj = {version: 'x25519-xsalsa20-poly1305'}
  obj.nonce = hexToBase64(hex.substr(6, lengths[0]))
  obj.ephemPublicKey = hexToBase64(hex.substr(6+lengths[0], lengths[1]))
  obj.ciphertext = hexToBase64(hex.substr(6+lengths[0]+lengths[1]))
  return obj
}

window.encodeObjAsHex = function(obj) {
  const buf = Buffer.from(JSON.stringify(obj), 'utf8')
  return '0x' + buf.toString('hex')
}

window.encryptMsgWithKey = function(msg, encryptionPublicKey) {
  const obj = sigUtil.encrypt(encryptionPublicKey, {data: msg}, 'x25519-xsalsa20-poly1305')
  nonce = base64ToHex(obj.nonce)
  ephemPublicKey = base64ToHex(obj.ephemPublicKey)
  ciphertext = base64ToHex(obj.ciphertext)
  const buf = Buffer.from([nonce.length, ephemPublicKey.length])
  const hex = '0x' + buf.toString('hex')+nonce+ephemPublicKey+ciphertext
  return hex
}
