TOP_DIR = ../..
include $(TOP_DIR)/tools/Makefile.common

DEPLOY_RUNTIME ?= /kb/runtime
TARGET ?= /kb/deployment

APP_SERVICE = app_service

SERVICE = SolrProxy
SERVICE_NAME = $(SERVICE)
SERVICE_URL = https://p3.theseed.org/services/$(SERVICE)
SERVICE_MODULE = lib/Bio/P3/SolrProxy/Service.pm
SERVICE_PORT = 7099
SERVICE_PSGI_FILE = $(SERVICE_NAME).psgi
SERVER_SPEC = $(SERVICE).spec

SRC_PERL = $(wildcard scripts/*.pl)
BIN_PERL = $(addprefix $(BIN_DIR)/,$(basename $(notdir $(SRC_PERL))))
DEPLOY_PERL = $(addprefix $(TARGET)/bin/,$(basename $(notdir $(SRC_PERL))))

SRC_SERVICE_PERL = $(wildcard service-scripts/*.pl)
BIN_SERVICE_PERL = $(addprefix $(BIN_DIR)/,$(basename $(notdir $(SRC_SERVICE_PERL))))
DEPLOY_SERVICE_PERL = $(addprefix $(SERVICE_DIR)/bin/,$(basename $(notdir $(SRC_SERVICE_PERL))))

CLIENT_TESTS = $(wildcard t/client-tests/*.t)
SERVER_TESTS = $(wildcard t/server-tests/*.t)
PROD_TESTS = $(wildcard t/prod-tests/*.t)

STARMAN_WORKERS = 8
STARMAN_MAX_REQUESTS = 100

TPAGE_ARGS = --define kb_top=$(TARGET) --define kb_runtime=$(DEPLOY_RUNTIME) --define kb_service_name=$(SERVICE) \
	--define kb_service_port=$(SERVICE_PORT) --define kb_service_dir=$(SERVICE_DIR) \
	--define kb_sphinx_port=$(SPHINX_PORT) --define kb_sphinx_host=$(SPHINX_HOST) \
	--define kb_starman_workers=$(STARMAN_WORKERS) \
	--define kb_starman_max_requests=$(STARMAN_MAX_REQUESTS) \
	--define kb_psgi=$(SERVICE_PSGI_FILE) \
	--define data_api_url=$(DATA_API_URL) \
	--define solr_url=$(SOLR_URL) \
	--define solr_user=$(SOLR_USER) \
	--define solr_pass=$(SOLR_PASS) \
	--define collection_credentials_file=$(COLLECTION_CREDENTIALS_FILE)


all: bin build-libs compile-typespec

build-libs: 
	$(TPAGE) $(TPAGE_BUILD_ARGS) $(TPAGE_ARGS) AppConfig.pm.tt > lib/Bio/P3/SolrProxy/AppConfig.pm

service: $(SERVICE_MODULE)

# psgi file was created with this paramter to compile_typespec. Removed here
# and file added to git so edits can be made.
# --psgi $(SERVICE_NAME).psgi 


compile-typespec: Makefile
	compile_typespec \
		--patric \
		--impl Bio::P3::$(SERVICE_NAME)::%sImpl \
		--service Bio::P3::$(SERVICE_NAME)::Service \
		--client Bio::P3::$(SERVICE_NAME)::Client \
		--url $(SERVICE_URL) \
		$(SERVER_SPEC) lib
	-rm -f lib/$(SERVER_MODULE)Server.py
	-rm -f lib/$(SERVER_MODULE)Impl.py
	-rm -f lib/CDMI_EntityAPIImpl.py

bin: $(BIN_PERL) $(BIN_SERVICE_PERL)

deploy: deploy-all
deploy-all: deploy-client  deploy-service
deploy-client: compile-typespec build-libs deploy-libs deploy-scripts deploy-docs

deploy-service: deploy-dir deploy-libs deploy-scripts deploy-service-scripts deploy-specs
	for script in start_service stop_service ; do \
		$(TPAGE) $(TPAGE_DEPLOY_ARGS) $(TPAGE_ARGS) service/$$script.tt > $(TARGET)/services/$(SERVICE)/$$script ; \
		chmod +x $(TARGET)/services/$(SERVICE)/$$script ; \
	done

deploy-dir:
	if [ ! -d $(SERVICE_DIR) ] ; then mkdir $(SERVICE_DIR) ; fi
	if [ ! -d $(SERVICE_DIR)/bin ] ; then mkdir $(SERVICE_DIR)/bin ; fi

deploy-docs: 


clean:


$(BIN_DIR)/%: service-scripts/%.pl $(TOP_DIR)/user-env.sh
	$(WRAP_PERL_SCRIPT) '$$KB_TOP/modules/$(CURRENT_DIR)/$<' $@

$(BIN_DIR)/%: service-scripts/%.py $(TOP_DIR)/user-env.sh
	$(WRAP_PYTHON_SCRIPT) '$$KB_TOP/modules/$(CURRENT_DIR)/$<' $@

include $(TOP_DIR)/tools/Makefile.common.rules
