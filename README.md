# GraphRAG Setup on Intel Gaudi2
The guide is evaluated based on the [GenAIExample PR](https://github.com/opea-project/GenAIExamples/pull/1007) and [GenAIComps PR](https://github.com/opea-project/GenAIComps/pull/793)
The GraphRAG services can be deployed on Intel Gaudi2 and Intel Xeon Scalable Processors. GraphRAG quality depends heavily on the ability to extract a high quality graph. It is highly recommended to use the best model available to you. 
If you use Intel Xeon, it is better to use OpenAI for graph extraction and community building. 
If you use Intel Gaudi2, a high-quality model is recommended for better performance. 
Our current evaluation runs llama3 70b model on 8 Intel Gaudi2 cards. 

## Quick Start Deployment Steps:
1. Checkout GraphRAG source code
  ```bash
  git clone https://github.com/opea-project/GenAIExamples.git
  cd GenAIExamples
  git fetch origin pull/1007/head:gr
  git switch gr
  cd ..
  ```
2. Set up the environment variables.
  ```bash
   export HUGGINGFACEHUB_API_TOKEN=${your_hf_token} # needed for TGI/TEI models as we use llama3 model, apply for the token thru the url https://huggingface.co/meta-llama/Meta-Llama-3-70B-Instruct
   ```
   If you are in a proxy environment, also set the proxy-related environment variables:
   ```bash
   export host_ip=${your_hostname IP} #local IP, i.e "192.168.1.1"
   export http_proxy="Your_HTTP_Proxy"
   export https_proxy="Your_HTTPs_Proxy"
   export no_proxy=$no_proxy,${host_ip} #important to add {host_ip} for containers communication
   ```
3. Run startup script.
  ```bash
  cp script.sh GenAIExamples/GraphRAG/
  cp file-curie.txt GenAIExamples/GraphRAG/
  cp GenAIExamples/GraphRAG/docker_compose/intel/hpu/gaudi/compose.yaml GenAIExamples/GraphRAG/docker_compose/intel/hpu/gaudi/compose-noshard.yaml
  cp compose.yaml GenAIExamples/GraphRAG/docker_compose/intel/hpu/gaudi/
  ./script.sh # it would take a few mins to download llama3 model for the first time. 
  ```
4. Consume the GraphRAG Service.
   To chat with retrieved information, you need to upload a file using `Dataprep` service.
   ```bash
   curl -x "" -X POST \
    -H "Content-Type: multipart/form-data" \
    -F "files=@./file-curie.txt" \
    http://localhost:6004/v1/dataprep
   ```
   Consume the graphrag service.
   ```bash
   curl -x "" http://localhost:8888/v1/graphrag \
    -H "Content-Type: application/json" \
	  -d "{\"model\": \"gpt-4o-mini\",\"messages\": [{\"role\": \"user\",\"content\": \"Who is Marie Curie and what are her scientific achievements?\"}]}"
   ```
## Tear down the services
```bash
cd GenAIExamples/GraphRAG/docker_compose/intel/hpu/gaudi/
export host_ip=${your_hostname IP} #local IP, i.e "192.168.1.1"
source ./set_env.sh
export HUGGINGFACEHUB_API_TOKEN=${your_hf_token}
export NEO4J_PASSWORD=password 
docker compose down
```

