import '../styles/globals.css'
import Link from 'next/link'
import Navbar from './components/Navbar'

function MyApp({ Component, pageProps }) {
  return (  
    <div className="gradient-bg-welcome h-screen">
      <nav className="w-full flex md:justify-center justify-between items-center p-4">
        <div className="md:flex-[0.5] flex-initial justify-center item-center">
          <Link href="/">
            <a className="text-3xl font-bold text-white cursor-pointer">Creatsy</a>
          </Link>
        </div>
        <ul className="text-white md:flex hidden list-none flex-row justify-between items-center flex-initial">
          <Link href="/Create">
            <a className="mx-4 cursor-pointer ">
              Create
            </a>
          </Link>
          <Link href="/Collection">
            <a className="mx-4 cursor-pointer">
              My Collection
            </a>
          </Link>
          <Link href="/Dashboard">
            <a className="mx-4 cursor-pointer">
              Dashboard
            </a>
          </Link>
          
        </ul>
      </nav>
      <Component {...pageProps} />
    </div>
  )
}

export default MyApp