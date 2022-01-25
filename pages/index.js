import { ethers } from 'ethers'
import { useEffect, useState } from 'react'
import axios from 'axios'
import Web3Modal from 'web3modal'

import {
  nftaddress, nftmarketaddress
} from '../config'

import NFT from '../artifacts/contracts/NFT.sol/NFT.json'
import Market from '../artifacts/contracts/NFTMarket.sol/NFTMarket.json'


export default function Home() {
  const [nfts, setNfts] = useState([])
  const [loadingState, setLoadingState] = useState('not-loaded')

  useEffect(() => {
    loadNFTs()
  }, [])

  async function loadNFTs() {
    const provider = new ethers.providers.JsonRpcProvider("https://matic-mumbai.chainstacklabs.com")
    const tokenContract = new ethers.Contract(nftaddress, NFT.abi, provider)
    const marketContract = new ethers.Contract(nftmarketaddress, Market.abi, provider)
    const data = await marketContract.fetchMarketItems() //unsold

    const items = await Promise.all(data.map(async i => {
      const tokenUri = await tokenContract.tokenURI(i.tokenId)
      const meta = await axios.get(tokenUri) 
      let price = ethers.utils.formatUnits(i.price.toString(), 'ether')
      let item = {
        price,
        tokenId: i.tokenId.toNumber(),
        seller: i.seller,
        owner: i.owner,
        image: meta.data.image,
        name: meta.data.name,
        description: meta.data.description,
      }
      return item
    }))
    setNfts(items)
    setLoadingState('loaded')
  }

  async function buyNft(nft) {
    const web3Modal = new Web3Modal()
    const connection = await web3Modal.connect()
    const provider = new ethers.providers.Web3Provider(connection)

    const signer = provider.getSigner()
    const contract = new ethers.Contract(nftmarketaddress, Market.abi, signer)

    const price = ethers.utils.parseUnits(nft.price.toString(), 'ether') // get price
    const transaction = await contract.createMarketSale(nftaddress, nft.tokenId, {
      value: price // money that is trasacted out of the users wallet
    })
    await transaction.wait()
    loadNFTs()
  }

  if (loadingState === 'loaded' && !nfts.length) return (
    <h1 className="py-10 text-3xl text-center">No items in marketplace</h1>
  )

  return (
    <div className="flex justify-center py-2">
      <div className="px-4" style={{ maxWidth: '1600px' }}>
      <h2 className="text-3xl py-8 text-center">Explore our collection of NFT Bonds</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 pt-4">
          { // bg-[#e3dfc3]
            nfts.map((nft, i) => (
              <div key={i} className="border shadow rounded-xl overflow-hidden bg-black border-3 border-inherit">
                <img src={nft.image} className="h-64 w-full object-cover"/>
                <div className="p-4">
                  <p style={{ height: '40px' }} className="text-2xl font-semibold text-center text-white">{nft.name}</p>
                  <div style={{ height: '20px', overflow: 'hidden' }}>
                    <p className="text-white text-center">{nft.description}</p>
                  </div>
                </div>
                <div className="p-4 bg-blakc">
                  <p className="text-xl mb-4 font-bold text-white">{nft.price} Matic</p>
                  <button className="w-full bg-[#b52d5d] text-white font-bold py-2 px-12 rounded" onClick={() => buyNft(nft)}>Buy</button>
                </div>
              </div>
            ))
          }
        </div>
      </div>
    </div>
  )
}
