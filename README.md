# GuardianNet

Proteção digital infantil com inteligência artificial.

O GuardianNet nasceu de uma pergunta simples: como saber se o seu filho está trocando mensagens com alguém perigoso, sem precisar ler tudo o que ele escreve? A resposta que estamos construindo é um app + site que analisa as conversas em tempo real e avisa os responsáveis quando algo parece errado — aliciamento, bullying, assédio, conteúdo impróprio, ameaças.

Projeto desenvolvido para a segunda fase do Empreenda SENAC. Ainda é um MVP, então nem tudo está 100% pronto — e isso está detalhado mais abaixo com transparência, sem exagerar no que já funciona.

> Pensado desde o início para seguir a Lei 15.211/2025: o monitoramento é transparente, a criança sabe que está sendo protegida e não é uma ferramenta de espionagem escondida.

## O que o app faz

- Analisa mensagens e classifica o risco em três níveis: seguro, atenção ou perigo
- Manda alerta pro responsável assim que algo suspeito é detectado
- Deixa os pais cadastrarem contatos de confiança (família, amigos, professores) pra não gerar alerta à toa
- Faz o pareamento do celular da criança com um código de 6 dígitos, sem precisar criar e-mail/senha pra ela
- Tem planos de assinatura (Básico e Premium) contratados pelo site
- Mostra histórico e relatórios dos alertas
- Tela própria pra criança, com botão de "Estou bem!" e um SOS pra emergência

## Como é montado por dentro

Três partes conversando entre si por API:

- **App (Flutter)** — onde o responsável e a criança usam o dia a dia: alertas, contatos, pareamento
- **Backend (Python/Flask, rodando no Render)** — cuida de login, assinaturas, e é quem fala com a IA
- **Site (Vercel)** — onde a pessoa conhece o produto, assina um plano e gerencia a conta

O banco é PostgreSQL no Supabase, que também guarda o modelo de IA já treinado (porque o Render, no plano free, apaga os arquivos toda vez que reinicia).

## A parte de IA

Não é só um filtro de palavrão. O processo tem algumas camadas:

1. Primeiro checa se quem mandou a mensagem é um contato de confiança — se for, nem precisa analisar
2. Depois passa por um dicionário de palavras-chave em português, com peso diferente pra cada categoria de risco (aliciamento, isolamento, manipulação, etc)
3. Em paralelo, um modelo Naive Bayes (biblioteca River, que aprende aos poucos, sem precisar retreinar do zero) avalia a mensagem — foi treinado em cima do corpus PAN12, que é uma base conhecida de identificação de predadores. Já temos o corpus traduzido pra português, além do original em inglês
4. No final, vale o pior resultado entre as duas análises, pra não deixar nada passar

## Tecnologias

- Flutter (mobile)
- Python + Flask (API)
- PostgreSQL via Supabase
- River (machine learning incremental)
- Corpus PAN12 (original em inglês e já traduzido pra português com argostranslate)
- Render (hospedagem da API) e Vercel (site)
- Autenticação com token opaco (não é JWT) — dá pra derrubar a sessão de um usuário na hora, o que faz sentido num app pensado pra proteção de criança

## Quem usa

- **Responsável**: cria conta e assina um plano pelo site, depois usa o mesmo login no app
- **Criança**: entra só com nome + código de pareamento de 6 dígitos

## Onde está o projeto agora

O que já funciona:
- Login, planos e assinaturas ligados de verdade ao backend
- Pareamento do celular da criança
- As telas do app (responsável e criança), com identidade visual própria
- Rota de análise de mensagem pela IA já no ar

O que falta:
- Contatos e alertas no app ainda usam dados de exemplo — a API real pra isso ainda não foi construída
- Ler as mensagens direto do celular via API de Acessibilidade do Android (hoje ainda é manual/simulado)
- Retreinar o modelo em cima do corpus já traduzido pra português

---

Projeto acadêmico para o Empreenda SENAC.
