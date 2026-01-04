# Navodila za zagon v oblaku
azure seizure confirmed

## -1. AMAZING DISCLAIMER

Saj nisem mogel najti nastavitev s katerimi bi vspostavil AKS cluster, problemi so bili z vezrijami, cenami in nedostopnosti node poolov glede na moj studentski plan, sem se odločil za uporabo AVM (Virtual Machine).

Pri nastavitvah VMa in celetnega procesa objave mikrostoritev v njem, sem si pomagal z raznimi viri, ampak najbolj uporaben je bil:

- https://github.com/Project-Fritata/fritata-backend

Iskreno hvala avtorju @kremec, za vs research, ki je bil potreben za vzpostavitev celotne infrastrukture. Brez tega repozitorija in njegove dokumentacije, ta del projekta najvrjetneje ne bi bil zaključen do roka.

Hvala <3


## 0. Skupne zahteve

- Azure račun
- Vercel račun
- Clerk račun in ustvarjena clerk aplikacija (za env spremenljivke)
- CoinGecko račun (za env spremenljivke)

## 1. Nastavitvev azure struktire

V azure portalu ustvarite naslednje storitve:

- Resource Group
- Azure Database for PostgreSQL Flexible Server
    - Database za vsako mikrostoritev posebej: payment, post, user
- Azure Container Registry
- Azure Blob Storage
- Azure Virtual Machine (Linux)
    - Location: Switzerland North (Zone 2)
    - Size: Standard B2s (2 vCPU, 4 GiB RAM)
    - Operating System: Ubuntu 24.04 LTS
    - Inbound port rules: Allow SSH (22), HTTPS (443)

## 2. Zagon in osnovna konfiguracija VM

Povežite se na vašo VM preko SSH in izvedite naslednje korake:
`.pem` datoteko dobite ob ustvarjanju VM-ja v Azure portalu.

```bash
ssh -i <PATH TO .pem FILE> <USERNAME>@<PUBLIC VM IP>
```

Ko ste povezani, izvedite naslednje ukaze za namestitev potrebnih orodij:

```bash
sudo apt update
sudo apt upgrade -y
sudo reboot
#nalozimo docker
sudo apt install docker.io -y
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
newgrp docker
#nalozimo minikube in kubectl
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
curl -LO https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
minikube start --driver=docker
minikube addons enable ingress
#nalozimo caddy
sudo apt install -y caddy
```

## 3. Nastavitev caddy strežnika

Uredite caddy konfiguracijsko datoteko:

```bash
#dobis minikube ip za uporabo v caddy konfiguraciji
minikube ip
sudo nano /etc/caddy/Caddyfile
```

odpre se datoteka, v katero vnesete naslednjo vsebino (prilagodite domene in IP naslove glede na vašo konfiguracijo):

```
<TVOJ_PUBLIC_VM_IP>.nip.io {
    # User Service
    reverse_proxy /users* <TVOJ_MINIKUBE_IP>:30001
    reverse_proxy /whoami* <TVOJ_MINIKUBE_IP>:30001
    reverse_proxy /value* <TVOJ_MINIKUBE_IP>:30001
    reverse_proxy /healthuser* <TVOJ_MINIKUBE_IP>:30001
                    
    # Post Service
    reverse_proxy /posts* <TVOJ_MINIKUBE_IP>:30002
    reverse_proxy /internal/posts* <TVOJ_MINIKUBE_IP>:30002
    reverse_proxy /healthpost* <TVOJ_MINIKUBE_IP>:30002
                    
    # Payment Service
    reverse_proxy /transactions* <TVOJ_MINIKUBE_IP>:30003
    reverse_proxy /paymentIntents* <TVOJ_MINIKUBE_IP>:30003
    reverse_proxy /payments* <TVOJ_MINIKUBE_IP>:30003
    reverse_proxy /healthpayment* <TVOJ_MINIKUBE_IP>:30003
                    
    # Frontend (catch-all)
    reverse_proxy /* <TVOJ_MINIKUBE_IP>:30000
                    
    log {
        output file /var/log/caddy/access.log
        format json
    }
}     
```

NOTE: frontend je najvrjetneje nepotreben, bolj kot ne za debugging
shrani in zapusti (CTRL+X, Y, ENTER)

Zaženi caddy z novo konfiguracijo:
```bash
sudo systemctl enable caddy
sudo systemctl start caddy
```

## 4. Potrebne datoteke in struktura VM
Na vaši VM ustvarite sledečo strukturo map in datotek:
```bash
.
├── k8s
│   ├── config
│   │   ├── payment-service-configmap.yaml
│   │   ├── post-service-configmapyaml
│   │   └── user-service-configmap.yaml
│   ├── deployments
│   │   ├── payment-service-deployment.yaml
│   │   ├── post-service-deployment.yaml
│   │   └── user-service-deployment.yaml
│   ├── secrets
│   │   ├── payment-db-secret.yaml
│   │   ├── payment-service-secrets.yaml
│   │   ├── post-blob-secret.yaml
│   │   ├── posts-db-secret.yaml
│   │   └── user-db-secret.yaml
│   └── services
│       ├── payment-service-service.yaml
│       ├── post-service-service.yaml
│       └── user-service-service.yaml
└── kubectl
```

Vse opisne datoteke naj imajo enako vsebino kot jo imajo v mapah `/k8s/` repozitorijev.
POMEMBNO: Poskrbite, da so vse okoljske spremenljivke in nastavitve v datotekah `secrets` in `configmap` ustrezno nastavljene. Teh je kar veliko, vsi repozitoriji imajo `example` datoteke z opisi potrebnih vrednosti.
POMEMBNO 2: side notice, mors ustvart `post-blob-secret.yaml` in `payment-service-secrets.yaml` lokalno po examplu poleg vseh ostalih ti zelo pomembni in največkrat povzročita error če sta pozablejni.

V osnovnih repozitorijih nastavite ustrezne vrednost db konfiguracij in spremenljivk glede na vašo Azure strukturo.


### na kratko nekaj pomembnih env spremenljivk:
- Database povezave za vse tri mikroservise (host, port, dbname, username, password)
- Azure Blob Storage connection string za post mikroservis
- Clerk API JWT spremenljivke za vse tri mikroservise
- CoinGecko API key za payment mikroservis
- Naslovi/povezave mikroservisov v configmap datotekah npt: `http://user-service:8080`


## 5. Zagon mikroservisov v Minikube
Na VMu izvedite ukaze za zagon mikroservisov:
```bash
kubectl apply -f k8s/secrets/
kubectl apply -f k8s/config/
kubectl apply -f k8s/services/
kubectl apply -f k8s/deployments/
#preveri če so vsi podi zagnani
kubectl get pods -w
```

Sedaj so vse tri mikrostoritve zagnane v Minikube okolju na vaši VM in dostopne preko Caddy strežnika in public VM IPja.

## 6. Nastavitve priprave okolja za frontend
Frontend aplikacije teče v Vercel oblaku
V Vercel dashboard-u ustvarite nov projekt in povežite vaš frontend repozitorij iz GitHub-a. Tako se ustvari tudi CI/CD pipeline za avtomatski zagon ob vsakem push-u v glavno vejo repozitorija na Vercel strani.

POMEMBNO: Projekt ustvarite tako da poveđete github repozitorij frontenda. Nastavite ustrezne okoljske spremenljivke in build nastavitve.

### Okoljske spremenljivke za Vercel frontend projekt:
- NEXT_PUBLIC_USER_API_URL = http://<TVOJ_PUBLIC_VM_IP>.nip.io
- NEXT_PUBLIC_POST_API_URL = http://<TVOJ_PUBLIC_VM_IP>.nip.io
- NEXT_PUBLIC_PAYMENT_API_URL = http://<TVOJ_PUBLIC_VM_IP>.nip.io
- NEXT_PUBLIC_API_BASE_URL = http://<TVOJ_PUBLIC_VM_IP>.nip.io
- NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY = <TVOJ_CLERK_PUBLISHABLE_KEY>
- CLERK_SECRET_KEY = <TVOJ_CLERK_SECRET_KEY>

In toj to, Vercel poskrbi za ostale build nastavitve in zagon. Provida tudi SSL certifikate avtomatsko. Prav tako je optimiziran za next.js aplikacije kot je ta.

## 7. Posodobitev dovoljenih povezav ki dostopajo do mikroservisov
V vsakem repozitoriju mikrostoritev (payment, post, user) posodobite dovoljene domene ki lahko dostopajo do mikroservisov preko CORS nastavitev. To naredite tako da v datoteki `WebConfig.java` ki je v mapi `src/main/java/com/example/<service>/config/` posodobite katere domene so dovoljene., ta mora biti IP vašega Vercel frontenda.

---

# Navodila za postavitev CI/CD pipeline-a

## 1. Nastavitev CI/CD za GitHub Actions (vse mikrostoritve)

V vsakem repozitoriju mikrostoritev (payment, post, user) že ustvarjen `.github/workflows/ci-cd.yml` datoteka z potrebno vsebino.

Na vseh lastnih verzijah github repozitorijev, v nastavitvah repozitorija, pod "Secrets and variables" -> "Actions", dodajte naslednje skrivnosti (secrets):
- ACR_LOGIN_SERVER (dobite iz Azure Container Registry-ja)
- ACR_USERNAME (dobite iz Azure Container Registry-ja)
- ACR_PASSWORD (dobite iz Azure Container Registry-ja)
- VM_HOST (javna IP vašega VM)
- VM_USER (uporabniško ime vaše VM)
- VM_SSH_KEY (vsebina vaše `.pem` datoteke)

## 2. Nastavitev CI/CD za Vercel (frontend)

Za Vercel ni potrebno narediti nič, saj že sam, ob tem ko smo pri prešnjem delu ustvarili projekt in povezali github repozitorij, poskrbi za avtomatsko integracijo in deployment ob vsakem push-u v glavno vejo repozitorija.

---

# Navodila za lokalni zagon
## 1. Kopiranje skript za zagon in zaustavitev
Za enostavni lokalni zagon in zaustavitev vseh storitev sem naredil skripti `runAll.bat` in `stopAll.bat`.
Te skripti kopirajte v glavno mapo projekta, kjer se nahajajo mape repozitorijev posameznih mikroservisov, drontenda in mape z Docker konfiguracijami.

primer strukture glavne mape projekta:

```
main-folder/
│── frontend/
│── payment/
│── post/
│── user/
│── docker/
│── runAll.bat
│── stopAll.bat
```

Vsaka mikrostoritev ter frontend že imajo implementirane lokalne skripte za zagon, oblik `run-dev-example.bat`. Glede na te, naredite svoje skripte `run-dev.bat` v vsakem repozitoriju (razen docker, ta ima glede na docker že implementirane klice znotraj `run-all/stop-all.bat` datotek). Vsake `run-dev.bat` dopolnite z ustraznimi okoljskimi spremenljivkami in nastavitvami, ki so potrebne za zagon posamezne storitve.

Ko imate to pripravljeno, zaženite docker desktop aplikacijo.

## 2. Zagon vseh storitev

Za zagon vseh storitev naenkrat:

```bat
./runAll.bat
```

## 3. Zaustavitev vseh storitev

Za zaustavitev vseh storitev naenkrat:

```bat
./stopAll.bat
```

---

# Dokumentacija projekta

## 1. Tehnična dokumentacija

### Opis projekta

Projekt je sestavljen iz več mikroservisov (frontend, payment, post, user), ki skupaj tvorijo aplikacijo.

Aplikacija je enostavna pseudo-anonimna platforma za prodajanje digitalnih izdelkov preko kriptovalut.

### Struktura projekta

- **frontend/** – uporabniški vmesnik (Next.js, Tailwind CSS, shadcn/ui)
- **payment/** – mikroservis za plačila (Java, Spring Boot, Web3j, PostgreSQL)
- **post/** – mikroservis za objave (Java, Spring Boot, PostgreSQL)
- **user/** – mikroservis za uporabnike (Java, Spring Boot, PostgreSQL)
- **docker/** – Docker Compose konfiguracije
- **DokumentacijaZNavodiliZagona/** – navodila in dokumentacija

### Nestandardna uporabljena orodja / Zunanji API / Knjižnice

- **frontend/** – Vercel V0 (osnovna oblika uporabniškega vmesnika), Metamask (kriptodenarnica), Clerk (avtentikacija, specializirane UI komponente)
- **payment/** – Web3j (interakcija s kriptovalutami), Clerk SDK (JWT avtentikacija), CoinGecko API (pridobivanje cen POL/USDC 1:1 POL/USD)
- **post/** – Azure Blob Storage (shranjevanje datotek), Azurite (lokalni emulator za Azure Blob Storage), Clerk SDK (JWT avtentikacija)
- **user/** – Clerk SDK (JWT avtentikacija)

### Dobre prakse

- Vse mikrostoritve so dodatno bolj temeljito dokumentirane znotraj njihovih repozitorijev `README.md`. (Oblika je mogoče malo nejasna, uporabljal sem jih za sprotno beleženje in dokumentiranje med razvojem, morda celo ne najbolj natančna). Ima opisane funkcionalnosti, uporabljene tehnologije, podrobnejša navodila za zagon, entitete, API končnice in podobno.

### Med razvojom so bile sproti glede na predavanja upoštevane dobre prakse razvoja, kot so:

- ločevanje odgovornosti, 
- uporaba DTO-jev, 
- debug kode/pozivnikov, 
- repozitorijev, 
- ustrezno ravnanje z napakami, 
- validacije vhodnih podatkov, 
- uporaba okoljskih spremenljivk za konfiguracije,
- SAS tokene za dostop do Azure Blob Storage (casovno omejeni dostop),
- JWT avtentikacija z uporabo Clerk storitve v vseh mikroservisih povezanih s frontend-om,
- logična struktura projektov in map,
- jasno poimenovane datoteke, funkcije, sremenljivke,
- in druge.


## 2. Dokumentacija API-jev mikroservisov

Dokumentacija API-jev je bila narejena s pomočjo orodja Swagger in je dostopna preko naslednjih URL-jev v lokalnem okolju, če so bile mokrostoritve zagnane lokalno glede na zgornja navodila:

- **User Service**: `http://localhost:8080/swagger-ui/index.html`
- **Post Service**: `http://localhost:8081/swagger-ui/index.html`
- **Payment Service**: `http://localhost:8082/swagger-ui/index.html`

---

*Zadnja posodobitev: 3. 1. 2026*