BIN_DIR=_output/bin
RELEASE_VER=v0.2
REPO_PATH=github.com/kubernetes-sigs/kube-batch
GitSHA=`git rev-parse HEAD`
Date=`date "+%Y-%m-%d %H:%M:%S"`

kube-batch: init
	go build  -ldflags " \
	-X '${REPO_PATH}/pkg/version.GitSHA=${GitSHA}' \
	-X '${REPO_PATH}/pkg/version.Built=${Date}'   \
	-X '${REPO_PATH}/pkg/version.Version=${RELEASE_VER}'" \
	-o _output/bin/kube-batch ./cmd/kube-batch

verify: generate-code
	hack/verify-gofmt.sh
	hack/verify-golint.sh
	hack/verify-gencode.sh

init:
	mkdir -p ${BIN_DIR}

generate-code:
	go build -o ${BIN_DIR}/deepcopy-gen ./cmd/deepcopy-gen/
	${BIN_DIR}/deepcopy-gen -i ./pkg/apis/scheduling/v1alpha1/ -O zz_generated.deepcopy

images: kube-batch
	cp ./_output/bin/kube-batch ./deployment/images/
	docker build ./deployment/images -t kubesigs/kube-batch:${RELEASE_VER}
	rm -f ./deployment/images/kube-batch

run-test:
	hack/make-rules/test.sh $(WHAT) $(TESTS)

e2e: kube-batch
	hack/run-e2e.sh

coverage:
	KUBE_COVER=y hack/make-rules/test.sh $(WHAT) $(TESTS)

clean:
	rm -rf _output/
	rm -f kube-batch
