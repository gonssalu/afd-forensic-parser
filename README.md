# process.ps1

Este script utiliza as tools do Zimmerman para dar parse, automaticamente, a todos os artefactos no registry do Windows, à AmCache e as JumpLists.

## Requisitos

- Ter as ZimmermanTools
- Correr este comando na Powershell: `Set-ExecutionPolicy Unrestricted -Scope CurrentUser`.
  Sem esse comando, por motivos de segurança, a Powershell impede a execução de scripts que não estejam assinados digitalmente.

## Sintaxe

A sintaxe do script é a seguinte:
`.\process.ps1 -ZimmermanTools "<Path ZimmermanTools>" -InputPath "<Input Path>" -OutputPath "<Output Path>"`

Para além disso existe ainda uma flag opcional `-DebugMode` que quando presente mostra o output de cada ferramenta empregue pelo script. Fica ganda spam por isso recomendo utilizarem apenas se der algum problema para poderem ver de onde vem o erro.

### Zimmerman Tools

No `-ZimmermanTools` colocam o path, **com o net6**, de onde têm as tools guardadas. (ex: "C:\ZimmermanTools\net6")

### Input Path

O `-InputPath` recebe o caminho para uma pasta onde devem estar todos os ficheiros a analisar. Devem estar na seguinte estrutura:

```
.
├── Users/
│   ├── 2123456/
│   │   ├── NTUSER.DAT
│   │   ├── UsrClass.dat
│   │   └── Recent/ (pasta)
│   └── 2654321/
│       └── ...
└── Global/
    ├── SOFTWARE
    ├── SYSTEM
    ├── SAM
    ├── SECURITY
    └── Amcache.hve
```

2123456 é um nome exemplo de uma das contas. A pasta Recent é a pasta que está no `%appdata%/Microsoft/Windows/Recent` (contém as cenas das JumpLists).
As cenas da pasta global são os ficheiros do registry do `system32/config`, o Amcache está no `Windows\appcompat\Programs\Amcache.hve`.
**Para que fique claro**, devem passar o path que inclui a pasta Users e Global.

### Output Path

A pasta onde irão ser guardados os resultados. (:warning: O script eliminará todos os conteúdos da pasta quando a ela já existe)

## Resultados

Os resultados sairão da seguinte forma:

- Dentro da pasta **Global** haverá um ficheiro CSV com os resultados da Análise pela ferramenta REcmd a todos os ficheiros que estavam na pasta Global do Input.
- Dentro da pasta **Global/AmCacheParserReport** estão os ficheiros CSV resultantes da análise ao Amcache.hve pela ferramenta AmCacheParser.
- Dentro da Pasta **Users** haverá um ficheiro CSV com os resultados das análises a **TODOS** os ficheiros NTUSER.dat e UsrClass.dat pela ferramenta REcmd.
- Dentro da Pasta **Users** existirá uma pasta para cada um dos utilizadores com os resultados da análise às JumpLists pela ferramenta JLEcmd.

_Nota: A ferramenta REcmd para além do ficheiro CSV cria também uma pasta com vários ficheiros CSV, esses ficheiros têm a mesma informação que o principal mas dividida por categorias. Pessoalmente, prefiro um único com tudo que vários com um pouco cada um, mas deixo à escolha de cada um_
