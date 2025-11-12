kubectl -n suite delete secret spotify-credentials 2>/dev/null || true
kubectl -n suite create secret generic spotify-credentials \
  --from-literal=clientId="$CID" \
  --from-literal=clientSecret="$SEC" \
  --from-literal=accessToken="BQAun76gDNg2zlb41KqCOGnzlhDhkWot1y_FFS0cJmcy1qjczrla8vYKCS68aQOzm7UrmRHUIXeLH2Qk51rS-l36GiYLhFZzP4Ewp9gEtGpPhApbMHu8Vf8i6_K5fAl80HgDaVvlDR8qdCgcBL4gh4xL-y_Vya8CNQSke6Zmur0C4Gv-WIw6Cl6gzzc5kprh8mbMrPQfnn2z4-puU6_FzKhX2uv6Zct3rvFOSnAMvlU" \
  --from-literal=refreshToken="AQABMUpcg-JGQllr3PqPvnAaU0wTZEUf-_Dv18XEvPn9vm81r0Ehl2tz0KsbEI2h88PldGTjVQVNTkW74wr5DRNcIHg5YpeTcqEDRpKG_vr26bBkwWW0-yvskeiURveQJsg"
