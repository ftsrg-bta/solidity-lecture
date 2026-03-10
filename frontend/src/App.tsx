import { useState, useEffect } from 'react'
import { createPublicClient, createWalletClient, custom, http, parseEther, formatEther } from 'viem'
import { sepolia } from 'viem/chains'
import { abi } from './abi'
import { CONTRACT_ADDRESS} from './contract'

const publicClient = createPublicClient({
  chain: sepolia,
  transport: http(),
})

export default function App() {
  const [account, setAccount] = useState<string | null>(null)
  const [highestBid, setHighestBid] = useState<bigint | null>(null)
  const [highestBidder, setHighestBidder] = useState<string | null>(null)
  const [bidAmount, setBidAmount] = useState<string>('')
  const [status, setStatus] = useState<string>('')

  async function connect() {
    if (window.ethereum === undefined) {
      setStatus('No wallet detected.  Please install MetaMask.')
      return
    }

    const [address] = await window.ethereum.request({
      method: 'eth_requestAccounts'
    }) as string[]
    setAccount(address)
  }

  async function fetchAuctionState() {
    if (window.ethereum === undefined) {
      setStatus('No wallet detected.')
      return
    }

    const [bid, bidder] = await Promise.all([
      publicClient.readContract({
        address: CONTRACT_ADDRESS,
        abi,
        functionName: 'highestBid'
      }),
      publicClient.readContract({
        address: CONTRACT_ADDRESS,
        abi,
        functionName: 'highestBidder'
      }),
    ])
    setHighestBid(bid);
    setHighestBidder(bidder);
  }

  async function placeBid() {
    if (window.ethereum === undefined) {
      setStatus('No wallet detected.')
      return
    }

    try {
      setStatus('Waiting for bid confirmation...')
      const walletClient = createWalletClient({
        chain: sepolia,
        transport: custom(window.ethereum),
      })
      const hash = await walletClient.writeContract({
        account,
        address: CONTRACT_ADDRESS,
        abi,
        functionName: 'bid',
        value: parseEther(bidAmount),
      })
      setStatus(`Transaction sent: ${hash}`)
      await publicClient.waitForTransactionReceipt({ hash })
      setStatus('Bid placed successfully')
      fetchAuctionState()
    } catch (e) {
      if (e instanceof Error) {
        setStatus(`Error: ${e.message}`)
      } else {
        setStatus('An unknown error occurred')
      }
    }
  }

  async function withdraw() {
    if (window.ethereum === undefined) {
      setStatus('No wallet detected.')
      return
    }

    try {
      setStatus('Waiting for withdraw confirmation...')
      const walletClient = createWalletClient({
        chain: sepolia,
        transport: custom(window.ethereum),
      })
      const hash = await walletClient.writeContract({
        account,
        address: CONTRACT_ADDRESS,
        abi,
        functionName: 'withdraw',
      })
      setStatus(`Transaction sent: ${hash}`)
      await publicClient.waitForTransactionReceipt({ hash })
      setStatus('Withdrawal successful')
      fetchAuctionState()
    } catch (e) {
      if (e instanceof Error) {
        setStatus(`Error: ${e.message}`)
      } else {
        setStatus('An unknown error occurred')
      }
    }
  }

  useEffect(() => { fetchAuctionState() }, [])

  return (
    <div className="min-h-screen bg-gray-950 text-gray-100 p-8">
      <div className="max-w-lg mx-auto space-y-6">

        <h1 className="text-2xl font-bold">Auction Demo</h1>

        {/* Wallet connection */}
        {!account ? (
          <button
            onClick={connect}
            className="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-medium py-2 px-4 rounded-lg"
          >
            Connect Wallet
          </button>
        ) : (
          <div className="bg-gray-800 rounded-lg p-4 text-sm text-gray-300">
            Connected: <span className="text-white font-mono">{account}</span>
          </div>
        )}

        {/* Auction state */}
        <div className="bg-gray-800 rounded-lg p-4 space-y-2">
          <h2 className="font-semibold text-gray-300">Auction Status</h2>
          <p className="text-sm">
            Highest bid:{' '}
            <span className="text-white font-mono">
              {highestBid !== null ? `${formatEther(highestBid)} ETH` : '...'}
            </span>
          </p>
          <p className="text-sm">
            Highest bidder:{' '}
            <span className="text-white font-mono text-xs">
              {highestBidder ?? '...'}
            </span>
          </p>
          <button
            onClick={fetchAuctionState}
            className="text-xs text-indigo-400 hover:text-indigo-300"
          >
            Refresh
          </button>
        </div>

        {/* Place bid */}
        {account && (
          <div className="bg-gray-800 rounded-lg p-4 space-y-3">
            <h2 className="font-semibold text-gray-300">Place a Bid</h2>
            <input
              type="number"
              placeholder="Amount in ETH"
              value={bidAmount}
              onChange={e => setBidAmount(e.target.value)}
              className="w-full bg-gray-700 text-white rounded-lg px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500"
            />
            <button
              onClick={placeBid}
              className="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-medium py-2 px-4 rounded-lg"
            >
              Bid
            </button>
          </div>
        )}

        {/* Withdraw */}
        {account && (
          <div className="bg-gray-800 rounded-lg p-4 space-y-3">
            <h2 className="font-semibold text-gray-300">Withdraw</h2>
            <p className="text-sm text-gray-400">
              Claim your refund if you have been outbid.
            </p>
            <button
              onClick={withdraw}
              className="w-full bg-gray-600 hover:bg-gray-500 text-white font-medium py-2 px-4 rounded-lg"
            >
              Withdraw
            </button>
          </div>
        )}

        {/* Status */}
        {status && (
          <div className="bg-gray-800 rounded-lg p-4 text-sm text-gray-300 font-mono break-all">
            {status}
          </div>
        )}

      </div>
    </div>
  )
}
