import { useState,useEffect } from "react";
import Hero from "./components/hero/Hero";
// import Wallet from "./components/Wallet/Wallet";

import { ethers } from "ethers";
import {abi} from "./components/Wallet/ABI"
import "./index.css";
import Navbar from "./Navbar/navbar";

function App() {
  const [account, setAccount] = useState("");
  const [provider, setProvider] = useState(null);
  const [contract, setContract] = useState(null);

  useEffect(() => {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    //provider is used to only read from blockchain

    const loadProvider = async () => {
      if (provider) {
        window.ethereum.on("chainChanged", () => {
          window.location.reload();
        });

        window.ethereum.on("accountsChanged", () => {
          window.location.reload();
        });
        await provider.send("eth_requestAccounts", []);
        const signer = provider.getSigner();
        const address = await signer.getAddress();
        setAccount(address);
        let contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
        const contract = new ethers.Contract(
          contractAddress,
          abi,
          signer
        );
        setContract(contract);
        setProvider(provider);
      } else {
        console.error("metamask is not installed");
      }
    };
    provider && loadProvider();
  }, []);
  return (
    <>
      <Navbar account={account} contract={contract} provider={provider} />

      <Hero  account={account} contract={contract} providers={provider} />
    </>
  );
}

export default App;
