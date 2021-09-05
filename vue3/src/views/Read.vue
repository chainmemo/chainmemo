<template>
  <h1>Read My Memos</h1>
  <div class="normal">
    <p style="text-align: center"><button @click="list">List My Memos</button></p>
    <hr/>
    <template v-for="(entry, sn) in memos" :keys="entry.timestamp">
      <b>#{{sn+1}}<code>&nbsp;&nbsp;{{entry.timestamp}}&nbsp;&nbsp;</code></b>
      <button @click="remove" v-bind:id="entry.id" style="font-size:20px; width: 80px;">remove</button>
      <br/>
      <p>{{entry.content}}</p><br/>
    </template>
  </div>
</template>

<script>
function alertNoMemos() {
  alert("You have not written any memo yet")
}

export default {
  data() {
    return {
      memos: []
    }
  },
  methods: {
    async list() {
      if (typeof window.ethereum === 'undefined') {
        alertNoWallet()
        return
      }
      const provider = new ethers.providers.Web3Provider(window.ethereum)
      const signer = provider.getSigner()
      const myMemoAddress = getMyContract(await signer.getAddress())
      const code = await provider.getCode(myMemoAddress)
      if(code.length <= 2) {
        alertNoMemos()
        return
      }
      const memoContract = new ethers.Contract(myMemoAddress, MemoABI, provider);
      const memoCount = await memoContract.memoCount()
      if(memoCount == 0) {
        alertNoMemos()
        return
      }
      var newMemos = []
      const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' })
      for(var i=0; i<memoCount; i++) {
        var entry = {id: i}
	const raw = await memoContract.getMemo(i)
        //const decoder = new TextDecoder("utf-8")
	//const rawArray = hexToUint8Array(raw)
        //const memo = decoder.decode(rawArray)
	const encObj = hexToEncObj(raw)
        const memo = await window.ethereum.request({
          method: 'eth_decrypt',
          params: [encodeObjAsHex(encObj), accounts[0]]
        })
        if(memo.length < ISODateExample.length) {
          continue // incorrect
        }
        entry.timestamp = memo.substr(0, ISODateExample.length)
        entry.content = memo.substr(ISODateExample.length+1)
        newMemos.push(entry)
      }
      newMemos.sort(function(a,b) {
        return a.timestamp < b.timestamp
      })
      this.memos = newMemos.reverse()
    },
    async remove(event) {
      if (typeof window.ethereum === 'undefined') {
        alertNoWallet()
        return
      }
      alert("To remove "+event.target.id)
      const provider = new ethers.providers.Web3Provider(window.ethereum)
      const signer = provider.getSigner()
      const myMemoAddress = getMyContract(await signer.getAddress())
      const code = await provider.getCode(myMemoAddress)
      if(code.length <= 2) {
        alertNoMemos()
        return
      }
      //const gasPrice = await provider.getStorageAt("0x0000000000000000000000000000000000002710","0x00000000000000000000000000000000000000000000000000000000000000002")
      const memoContract = new ethers.Contract(myMemoAddress, MemoABI, provider)
      await memoContract.connect(signer).deleteMemo(event.target.id)// {gasPrice: gasPrice}
    }
  }
}
</script>
