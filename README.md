# All Bank

Aplicació Flutter de consulta, en català, castellà i anglès. De moment el
desenvolupament i les proves de plataforma se centren en Android. El codi
compartit i el projecte iOS es conserven, però iOS no s'ha compilat ni provat.

## Estat actual

App d'ús personal per consultar diversos bancs/brokers des d'un sol lloc.
Permet desbloquejar l'aplicació amb la biometria o el codi del dispositiu, i
afegir o treure les vuit entitats d'una llista local. Tres tenen una connexió
real implementada (CaixaBank, Trade Republic, DEGIRO); la resta (Revolut, ING,
MyInvestor, Pibank, Raisin) encara no en tenen cap i mostren les categories de
producte com a no disponibles -- vegeu "Accés a les entitats" per l'estat de
cadascuna. No hi ha entrada manual de saldo: si una entitat no té connexió,
simplement no mostra dades.

Només es desa localment, amb emmagatzematge protegit del dispositiu (Keychain
a iOS, Keystore/còpia de seguretat desactivada a Android): la llista
d'entitats seleccionades, les credencials/tokens de sessió de cada connexió
activa, i una còpia en cache (SQLite via drift) dels últims saldos consultats
de cada banc, per poder-los mostrar sense haver de tornar a consultar la xarxa
cada vegada. No hi ha servidor propi. La protecció del dispositiu no garanteix
risc zero.

## Accés a les entitats

Connectar-se directament a l'API PSD2 d'un banc (sense passar per un
agregador) requereix estar registrat legalment com a AISP (Account
Information Service Provider) davant el regulador competent, amb certificats
eIDAS -- un procés pensat per a empreses, inviable per a una app d'ús
personal. Per això cada entitat s'aborda amb la via més directa i menys
intermediada que és realment viable per a un particular:

- **CaixaBank:** via [GoCardless Bank Account Data](https://bankaccountdata.gocardless.com/)
  (agregador PSD2/AIS). Cal crear-hi un compte propi gratuït i introduir el
  `secret_id`/`secret_key` resultant a la pantalla d'ajustos de l'app -- són
  claus d'API de l'aplicació, mai la contrasenya del banc. En connectar,
  l'app obre el login oficial del propi banc (OAuth); la contrasenya del banc
  només s'introdueix allà. Els saldos sí que passen pels servidors de
  GoCardless abans d'arribar a l'app (no és "zero intermediaris", és
  "credencials sempre amb el banc, dades amb un intermediari regulat i
  revocable en qualsevol moment"). El PSD2 AIS només cobreix comptes de
  pagament: no inclou fons, plans de pensions ni carteres de valors del banc.
- **Trade Republic:** protocol no oficial reimplementat a partir del projecte
  obert [pytr-org/pytr](https://github.com/pytr-org/pytr), usant
  deliberadament el seu flux de login "v2": l'alternativa "v1" requereix
  superar un repte anti-bot (AWS WAF) normalment resolt amb un navegador sense
  interfície, inviable des d'una app mòbil. El flux v2 demana en lloc d'això
  un segon factor que l'usuari ja té: un codi de la seva app d'autenticador,
  o confirmar l'inici de sessió des de la pròpia app de Trade Republic.
  Credencials i sessió es guarden xifrades només al dispositiu; la
  comunicació és directa amb `api.traderepublic.com`.
- **DEGIRO:** DEGIRO [indica que no ofereix cap API](https://www.degiro.com/uk/helpdesk/trading-platform/does-degiro-offer-api)
  per a tercers. S'usa un protocol no oficial reimplementat a partir del
  projecte obert [Chavithra/degiro-connector](https://github.com/Chavithra/degiro-connector)
  (login REST + sessió per cookie, sense cap repte anti-bot conegut).
  Credencials i sessió es guarden xifrades només al dispositiu; la
  comunicació és directa amb `trader.degiro.nl`.
- **Revolut, ING, MyInvestor, Pibank, Raisin:** sense connexió. Revolut i
  MyInvestor només exposen una API PSD2 pensada per a proveïdors regulats
  (requereix certificat eIDAS/OBIE); DEGIRO i Trade Republic ja es tracten més
  amunt; per a Pibank i Raisin no s'ha trobat cap via (ni oficial ni amb
  protocol no oficial conegut). Això no demostra que no n'hi hagi cap.

Tant la connexió de CaixaBank com les reimplementacions de Trade
Republic/DEGIRO són per a **ús personal**, no per distribuir-les ni per ús
comercial: depenen de protocols no publicats o de condicions d'ús de tercers
que poden canviar o trencar-se sense avís.

## Desenvolupament

Instal·la [Devbox](https://www.jetify.com/devbox), i després:

```sh
devbox install
devbox run android-setup
devbox run test
devbox run analyze
devbox run -- flutter doctor
```

Devbox proporciona Flutter, Java, CocoaPods, Android CLI i ADB. L'ordre
`android-setup` descarrega l'Android SDK, les plataformes 35 i 36, les eines
de compilació corresponents, CMake i l'NDK dins `.devbox/android-sdk`. La instal·lació
utilitza Android CLI i està subjecta a les [condicions de l'SDK d'Android](https://developer.android.com/studio/terms).
Flutter pot indicar que desconeix l'estat de les llicències: les versions noves
de les eines d'Android ja no implementen l'opció `sdkmanager --licenses` que
Flutter consulta. Per a iOS cal instal·lar i configurar Xcode complet, acceptar
les seves llicències i configurar la signatura del dispositiu. Consulta
`flutter doctor` per als passos pendents.
Les proves de widgets utilitzen adaptadors simulats i no substitueixen les proves
de biometria i emmagatzematge en dispositius reals.

Amb les eines de plataforma configurades, executa `devbox run -- flutter run`
amb un dispositiu Android connectat, o genera un APK de proves amb
`devbox run -- flutter build apk --debug`. L'identificador `com.example.all_bank` és només
provisional i s'ha de canviar abans de distribuir l'aplicació.

Si es modifica l'esquema de la base de dades local (`lib/storage/app_database.dart`),
cal regenerar el codi de drift amb:

```sh
devbox run -- flutter pub run build_runner build --delete-conflicting-outputs
```

Per connectar CaixaBank cal primer crear un compte gratuït a
[bankaccountdata.gocardless.com](https://bankaccountdata.gocardless.com/) i
introduir el `secret_id`/`secret_key` resultant a la pantalla d'ajustos de
l'app abans d'intentar connectar-la.
