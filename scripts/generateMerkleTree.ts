import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";

// Define the addresses and token IDs for the whitelist
const whitelist = [
    {
        address: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
        tokenId: 1
    },
    {
        address: "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
        tokenId: 2
    },
    {
        address: "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
        tokenId: 3
    },
    // Add more addresses as needed
];

// Create values array for the merkle tree
const values = whitelist.map(entry => [entry.address, entry.tokenId.toString()]);

// Generate the merkle tree
const tree = StandardMerkleTree.of(values, ["address", "uint256"]);

// Save the tree
fs.writeFileSync("merkle-tree.json", JSON.stringify(tree.dump()));

// Generate and save proofs for each address
const proofs: Record<string, any> = {};
for (const [i, v] of tree.entries()) {
    const proof = tree.getProof(i);
    proofs[v[0]] = {
        proof,
        tokenId: v[1],
        leaf: tree.leafHash(v)
    };
}

fs.writeFileSync("proofs.json", JSON.stringify(proofs, null, 2));

// Output the root
console.log('Merkle Root:', tree.root);

// Output example proof verification data
const firstEntry = Object.entries(proofs)[0];
if (firstEntry) {
    const [address, data] = firstEntry;
    console.log('\nExample Proof Data for', address);
    console.log('Token ID:', data.tokenId);
    console.log('Proof:', data.proof);
}