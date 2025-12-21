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

## Opis projekta

Projekt je sestavljen iz več mikroservisov (frontend, payment, post, user), ki skupaj tvorijo aplikacijo.

Aplikacija je enostavna pseudo-anonimna platforma za prodajanje digitalnih izdelkov preko kriptovalut.

## Struktura projekta

- **frontend/** – uporabniški vmesnik (Next.js, Tailwind CSS, shadcn/ui)
- **payment/** – mikroservis za plačila (Java, Spring Boot, Web3j, PostgreSQL)
- **post/** – mikroservis za objave (Java, Spring Boot, PostgreSQL)
- **user/** – mikroservis za uporabnike (Java, Spring Boot, PostgreSQL)
- **docker/** – Docker Compose konfiguracije
- **DokumentacijaZNavodiliZagona/** – navodila in dokumentacija

## Nestandardna uporabljena orodja / Zunanji API / Knjižnice

- **frontend/** – Vercel V0 (osnovna oblika uporabniškega vmesnika), Metamask (kriptodenarnica), Clerk (avtentikacija, specializirane UI komponente)
- **payment/** – Web3j (interakcija s kriptovalutami), Clerk SDK (JWT avtentikacija), CoinGecko API (pridobivanje cen POL/USDC 1:1 POL/USD)
- **post/** – Azure Blob Storage (shranjevanje datotek), Azurite (lokalni emulator za Azure Blob Storage), Clerk SDK (JWT avtentikacija)
- **user/** – Clerk SDK (JWT avtentikacija)

## Dobre prakse

- Vse mikrostoritve so dodatno bolj temeljito dokumentirane znotraj njihovih repozitorijev `README.md`. (Oblika je mogoče malo nejasna, uporabljal sem jih za sprotno beleženje in dokumentiranje med razvojem, morda celo ne najbolj natančna). Ima opisane funkcionalnosti, uporabljene tehnologije, podrobnejša navodila za zagon, entitete, API končnice in podobno.
- Med razvojom so bile sproti glede na predavanja upoštevane dobre prakse razvoja, kot so ločevanje odgovornosti, uporaba DTO-jev, debug kode/pozivnikov, repozitorijev, ustrezno ravnanje z napakami, validacije vhodnih podatkov, uporaba okoljskih spremenljivk za konfiguracije in podobno.

---

*Zadnja posodobitev: 21. 12. 2025*