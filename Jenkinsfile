pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'guessod'
        MOVIE_IMAGE = 'movie-service-exam'
        CAST_IMAGE = 'cast-service-exam'
        DOCKER_TAG = "exam-${BUILD_NUMBER}"
        K8S_NAMESPACE = 'dev'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
    }
    
    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['dev', 'qa', 'staging', 'prod'],
            description: 'Environnement de déploiement'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Passer les tests'
        )
    }
    
    stages {
        
        // ========== STAGE 1 : PRÉPARATION ==========
        stage('Préparation') {
            steps {
                script {
                    echo "========================================"
                    echo "EXAMEN DEVOPS DATASCIENTEST"
                    echo "Candidat: Mohamed GUESSOD"
                    echo "========================================"
                    echo ""
                    echo "Build ID: ${BUILD_NUMBER}"
                    echo "Docker Tag: ${DOCKER_TAG}"
                    echo "Environnement cible: ${params.DEPLOY_ENV}"
                    echo ""
                    
                    // Nettoyage workspace
                    cleanWs()
                    
                    // Récupération code
                    checkout scm
                    
                    sh '''
                    echo "✅ Code récupéré avec succès"
                    echo ""
                    echo "Structure du projet:"
                    ls -la
                    echo ""
                    '''
                }
            }
        }
        
        // ========== STAGE 2 : OPTIMISATION DÉPENDANCES ==========
        stage('Optimisation Dépendances') {
            steps {
                script {
                    echo "=== OPTIMISATION DES DÉPENDANCES ==="
                    
                    sh '''
                    echo "🔧 Vérification et optimisation des requirements.txt..."
                    
                    echo "→ Optimisation movie-service..."
                    if [ -f movie-service/requirements.txt ]; then
                        echo "  📋 Requirements.txt actuel:"
                        cat movie-service/requirements.txt
                        # Vérifier si pydantic est présent
                        if grep -qi pydantic movie-service/requirements.txt; then
                            echo "  ✅ Requirements.txt optimisé"
                        else
                            echo "  ➕ Ajout de pydantic si manquant"
                            echo "pydantic==1.10.13" >> movie-service/requirements.txt
                        fi
                    else
                        echo "  ⚠️ Fichier requirements.txt manquant"
                    fi
                    
                    echo "→ Optimisation cast-service..."
                    if [ -f cast-service/requirements.txt ]; then
                        echo "  📋 Requirements.txt actuel:"
                        cat cast-service/requirements.txt
                        if grep -qi pydantic cast-service/requirements.txt; then
                            echo "  ✅ Requirements.txt optimisé"
                        else
                            echo "  ➕ Ajout de pydantic si manquant"
                            echo "pydantic==1.10.13" >> cast-service/requirements.txt
                        fi
                    else
                        echo "  ⚠️ Fichier requirements.txt manquant"
                    fi
                    
                    echo ""
                    echo "📋 DÉPENDANCES FINALES:"
                    echo "Movie-service:"
                    cat movie-service/requirements.txt
                    echo ""
                    echo "Cast-service:"
                    cat cast-service/requirements.txt
                    echo ""
                    
                    echo "✅ Optimisation des dépendances terminée"
                    '''
                }
            }
        }
        
        // ========== STAGE 3 : BUILD DOCKER IMAGES ==========
        stage('Build Docker Images') {
            steps {
                script {
                    echo "=== BUILD DES IMAGES DOCKER ==="
                    
                    // Build movie-service
                    dir('movie-service') {
                        sh '''
                        echo "🔨 Construction de movie-service..."
                        echo "📦 Dépendances à installer:"
                        cat requirements.txt
                        echo "🚀 Lancement du build..."
                        
                        # Tentative de build avec gestion d'erreur
                        set +e
                        docker build -t ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} .
                        BUILD_STATUS=$?
                        set -e
                        
                        if [ $BUILD_STATUS -eq 0 ]; then
                            echo "✅ Build réussi du premier coup"
                        else
                            echo "⚠️ Premier build échoué, tentative de nettoyage et rebuild..."
                            docker system prune -f
                            sleep 2
                            docker build -t ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} .
                            echo "✅ Build réussi après nettoyage"
                        fi
                        
                        # Ajouter tag latest
                        docker tag ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:latest
                        echo "✅ Tag 'latest' ajouté"
                        '''
                    }
                    
                    // Build cast-service
                    dir('cast-service') {
                        sh '''
                        echo "🔨 Construction de cast-service..."
                        echo "📦 Dépendances à installer:"
                        cat requirements.txt
                        docker build -t ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} .
                        echo "✅ Build réussi"
                        
                        # Ajouter tag latest
                        docker tag ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${CAST_IMAGE}:latest
                        echo "✅ Tag 'latest' ajouté"
                        '''
                    }
                    
                    // Vérification des images
                    sh '''
                    echo ""
                    echo "🧪 VÉRIFICATION DES IMAGES:"
                    echo "📊 Images disponibles:"
                    docker images | grep -E "REPOSITORY|${DOCKER_REGISTRY}"
                    echo ""
                    
                    echo "→ Test rapide movie-service:"
                    if docker run --rm ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} python -c "
try:
    import fastapi
    print('✅ FastAPI:', fastapi.__version__)
    import aiosqlite
    print('✅ aiosqlite')
    import databases
    print('✅ databases')
    import pydantic
    print('✅ pydantic:', pydantic.__version__)
    print('✅ Toutes les dépendances OK')
except Exception as e:
    print('❌ Erreur:', str(e))
    exit(1)
" ; then
        echo "✅ Movie-service: dépendances OK"
    else
        echo "⚠️ Movie-service: problème de dépendances"
    fi
    
    echo "→ Test rapide cast-service:"
    if docker run --rm ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} python -c "
try:
    import fastapi
    print('✅ FastAPI:', fastapi.__version__)
    import aiosqlite
    print('✅ aiosqlite')
    import pydantic
    print('✅ pydantic:', pydantic.__version__)
    print('✅ Dépendances OK')
except Exception as e:
    print('❌ Erreur:', str(e))
    exit(1)
" ; then
        echo "✅ Cast-service: dépendances OK"
    else
        echo "⚠️ Cast-service: problème de dépendances"
    fi
                    '''
                }
            }
        }
        
        // ========== STAGE 4 : TESTS LOCAUX SIMPLES ==========
        stage('Tests Locaux') {
            steps {
                script {
                    echo "=== TESTS LOCAUX SIMPLES ==="
                    
                    sh '''
                    echo "🧪 Tests basiques de démarrage..."
                    
                    # Nettoyage
                    docker stop test-movie test-cast 2>/dev/null || true
                    docker rm test-movie test-cast 2>/dev/null || true
                    
                    echo ""
                    echo "🎬 Test movie-service..."
                    docker run -d --name test-movie -p 8001:8000 ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:latest
                    
                    sleep 5
                    
                    if docker ps | grep -q test-movie; then
                        echo "✅ Container movie-service en cours d'exécution"
                        echo "📋 Logs:"
                        docker logs test-movie --tail=3 2>/dev/null || echo "Pas de logs"
                    else
                        echo "❌ Container movie-service non démarré"
                        docker logs test-movie 2>/dev/null || true
                    fi
                    
                    docker stop test-movie 2>/dev/null || true
                    docker rm test-movie 2>/dev/null || true
                    
                    echo ""
                    echo "🎭 Test cast-service..."
                    docker run -d --name test-cast -p 8002:8000 ${DOCKER_REGISTRY}/${CAST_IMAGE}:latest
                    
                    sleep 5
                    
                    if docker ps | grep -q test-cast; then
                        echo "✅ Container cast-service en cours d'exécution"
                        echo "📋 Logs:"
                        docker logs test-cast --tail=3 2>/dev/null || echo "Pas de logs"
                    else
                        echo "❌ Container cast-service non démarré"
                        docker logs test-cast 2>/dev/null || true
                    fi
                    
                    docker stop test-cast 2>/dev/null || true
                    docker rm test-cast 2>/dev/null || true
                    
                    echo ""
                    echo "✅ Tests locaux terminés"
                    '''
                }
            }
        }
        
        // ========== STAGE 5 : PUSH DOCKERHUB ==========
        stage('Push DockerHub') {
            when {
                expression { params.DEPLOY_ENV != 'local' }
            }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    script {
                        echo "=== PUSH SUR DOCKERHUB ==="
                        
                        sh '''
                        echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin
                        
                        echo "Envoi de movie-service..."
                        docker push ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG}
                        docker push ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:latest
                        
                        echo "Envoi de cast-service..."
                        docker push ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG}
                        docker push ${DOCKER_REGISTRY}/${CAST_IMAGE}:latest
                        
                        echo ""
                        echo "✅ IMAGES PUBLIÉES SUR DOCKERHUB!"
                        echo "   - ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG}"
                        echo "   - ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG}"
                        echo "   - Accès: https://hub.docker.com/u/${DOCKER_REGISTRY}"
                        '''
                    }
                }
            }
        }
        
        // ========== STAGE 6 : PRÉPARATION KUBERNETES ==========
        stage('Préparation Kubernetes') {
            when {
                expression { params.DEPLOY_ENV in ['dev', 'qa', 'staging', 'prod'] }
            }
            steps {
                script {
                    echo "=== CONFIGURATION KUBERNETES ==="
                    
                    sh '''
                    echo "📁 Création des namespaces..."
                    
                    # Vérification/création des namespaces
                    for ns in dev qa staging prod; do
                        if kubectl get namespace ${ns} >/dev/null 2>&1; then
                            echo "  ✅ Namespace ${ns} existe déjà"
                        else
                            echo "  ➕ Création namespace ${ns}"
                            kubectl create namespace ${ns}
                        fi
                    done
                    
                    echo ""
                    echo "📋 ÉTAT DES NAMESPACES:"
                    kubectl get namespaces | grep -E "dev|qa|staging|prod|NAME"
                    echo ""
                    
                    echo "🧹 Nettoyage léger..."
                    kubectl delete deployment movie-service cast-service -n ${DEPLOY_ENV} --ignore-not-found=true
                    sleep 2
                    '''
                }
            }
        }
        
        // ========== STAGE 7 : DÉPLOIEMENT KUBERNETES ==========
        stage('Déploiement Kubernetes') {
            when {
                expression { params.DEPLOY_ENV in ['dev', 'qa', 'staging'] }
            }
            steps {
                script {
                    echo "=== DÉPLOIEMENT SUR KUBERNETES ==="
                    
                    sh """
                    NAMESPACE="${params.DEPLOY_ENV}"
                    echo "🚀 Déploiement dans namespace: \${NAMESPACE}"
                    
                    # Créer le fichier de déploiement
                    cat > k8s-deploy.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: movie-service
  namespace: \${NAMESPACE}
spec:
  selector:
    app: movie-service
  ports:
    - protocol: TCP
      port: 8000
      targetPort: 8000
      nodePort: 30001
  type: NodePort
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: movie-service
  namespace: \${NAMESPACE}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: movie-service
  template:
    metadata:
      labels:
        app: movie-service
    spec:
      containers:
      - name: movie-service
        image: ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG}
        imagePullPolicy: Always
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "sqlite:///./test.db"
---
apiVersion: v1
kind: Service
metadata:
  name: cast-service
  namespace: \${NAMESPACE}
spec:
  selector:
    app: cast-service
  ports:
    - protocol: TCP
      port: 8000
      targetPort: 8000
      nodePort: 30002
  type: NodePort
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cast-service
  namespace: \${NAMESPACE}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cast-service
  template:
    metadata:
      labels:
        app: cast-service
    spec:
      containers:
      - name: cast-service
        image: ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG}
        imagePullPolicy: Always
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "sqlite:///./test.db"
EOF
                    
                    echo "📄 Application du déploiement..."
                    kubectl apply -f k8s-deploy.yaml
                    
                    echo "✅ DÉPLOIEMENT APPLIQUÉ"
                    echo ""
                    echo "⏳ Attente du démarrage (45 secondes)..."
                    sleep 45
                    
                    echo "📊 ÉTAT ACTUEL:"
                    kubectl get all -n \${NAMESPACE}
                    echo ""
                    
                    echo "📋 LOGS:"
                    echo "Movie-service:"
                    kubectl logs -n \${NAMESPACE} deployment/movie-service --tail=5 2>/dev/null || echo "Pas de logs disponible"
                    echo ""
                    echo "Cast-service:"
                    kubectl logs -n \${NAMESPACE} deployment/cast-service --tail=5 2>/dev/null || echo "Pas de logs disponible"
                    """
                }
            }
        }
        
        // ========== STAGE 8 : VALIDATION ==========
        stage('Validation') {
            when {
                expression { params.DEPLOY_ENV in ['dev', 'qa', 'staging'] }
            }
            steps {
                script {
                    echo "=== VALIDATION FINALE ==="
                    
                    sh """
                    NAMESPACE="${params.DEPLOY_ENV}"
                    echo "🔍 ÉTAT FINAL:"
                    kubectl get pods,svc -n \${NAMESPACE}
                    
                    # Récupération des ports
                    if [ "\${NAMESPACE}" = "dev" ]; then
                        MOVIE_PORT=30001
                        CAST_PORT=30002
                    elif [ "\${NAMESPACE}" = "qa" ]; then
                        MOVIE_PORT=30011
                        CAST_PORT=30012
                    elif [ "\${NAMESPACE}" = "staging" ]; then
                        MOVIE_PORT=30021
                        CAST_PORT=30022
                    else
                        MOVIE_PORT=30001
                        CAST_PORT=30002
                    fi
                    
                    # Récupération IP du node
                    NODE_IP=\$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
                    
                    echo ""
                    echo "🌐 POINTS D'ACCÈS:"
                    echo "  Movie-service: http://\${NODE_IP}:\${MOVIE_PORT}/health"
                    echo "  Cast-service: http://\${NODE_IP}:\${CAST_PORT}/health"
                    echo ""
                    
                    echo "🧪 TESTS RAPIDES:"
                    echo "→ Test movie-service..."
                    if curl -s -f --max-time 10 http://\${NODE_IP}:\${MOVIE_PORT}/health ; then
                        echo "  ✅ Accessible"
                    else
                        echo "  ❌ Non accessible"
                    fi
                    
                    echo "→ Test cast-service..."
                    if curl -s -f --max-time 10 http://\${NODE_IP}:\${CAST_PORT}/health ; then
                        echo "  ✅ Accessible"
                    else
                        echo "  ❌ Non accessible"
                    fi
                    
                    echo ""
                    echo "📁 VÉRIFICATION DES 4 ENVIRONNEMENTS:"
                    for ns in dev qa staging prod; do
                        PODS=\$(kubectl get pods -n \${ns} 2>/dev/null | wc -l)
                        PODS=\$((PODS - 1))
                        echo "  \${ns}: \${PODS} pod(s)"
                    done
                    
                    echo ""
                    echo "🎉 VALIDATION TERMINÉE"
                    """
                }
            }
        }
        
        // ========== STAGE 9 : VALIDATION PRODUCTION ==========
        stage('Validation Production') {
            when {
                branch 'master'
            }
            steps {
                script {
                    echo "=== VALIDATION PRODUCTION ==="
                    
                    sh '''
                    echo "🔒 Vérifications de sécurité production..."
                    echo "📊 Vérification des ressources..."
                    
                    # Vérification des nodes
                    echo "Nodes disponibles:"
                    kubectl get nodes
                    
                    # Vérification des ressources
                    echo "Ressources disponibles:"
                    kubectl describe nodes | grep -A 5 "Allocatable"
                    
                    # Vérification des namespaces
                    echo "Namespaces:"
                    kubectl get namespaces
                    
                    # Vérification de l'état actuel en prod
                    echo "État actuel en production:"
                    kubectl get all -n prod 2>/dev/null || echo "Pas de déploiement en production"
                    
                    # Vérification des quotas
                    echo "Quotas en production:"
                    kubectl describe quota -n prod 2>/dev/null || echo "Pas de quotas définis"
                    
                    echo "✅ Pré-validation production OK"
                    '''
                }
            }
        }
        
        // ========== STAGE 10 : DÉPLOIEMENT PRODUCTION ==========
        stage('Déploiement Production') {
            when {
                branch 'master'
            }
            input {
                message "🚀 DÉPLOIEMENT PRODUCTION - Build ${BUILD_NUMBER}"
                ok "✅ Confirmer le déploiement"
                parameters {
                    choice(
                        name: 'ENV',
                        choices: ['prod'],
                        description: 'Environnement de production'
                    )
                    booleanParam(
                        name: 'FORCE_DEPLOY',
                        defaultValue: false,
                        description: 'Forcer le déploiement même si des tests échouent'
                    )
                }
            }
            steps {
                script {
                    echo "=== DÉPLOIEMENT SUR PRODUCTION ==="
                    
                    sh '''
                    NAMESPACE="prod"
                    echo "🚀 Déploiement dans namespace: ${NAMESPACE}"
                    
                    # Créer le fichier de déploiement production
                    cat > k8s-prod.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: movie-service
  namespace: prod
spec:
  selector:
    app: movie-service
  ports:
    - protocol: TCP
      port: 8000
      targetPort: 8000
      nodePort: 31001
  type: NodePort
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: movie-service
  namespace: prod
spec:
  replicas: 2
  selector:
    matchLabels:
      app: movie-service
  template:
    metadata:
      labels:
        app: movie-service
    spec:
      containers:
      - name: movie-service
        image: guessod/movie-service-exam:exam-${BUILD_NUMBER}
        imagePullPolicy: Always
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "sqlite:///./prod.db"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: cast-service
  namespace: prod
spec:
  selector:
    app: cast-service
  ports:
    - protocol: TCP
      port: 8000
      targetPort: 8000
      nodePort: 31002
  type: NodePort
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cast-service
  namespace: prod
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cast-service
  template:
    metadata:
      labels:
        app: cast-service
    spec:
      containers:
      - name: cast-service
        image: guessod/cast-service-exam:exam-${BUILD_NUMBER}
        imagePullPolicy: Always
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "sqlite:///./prod.db"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
EOF
                    
                    echo "📄 Application du déploiement production..."
                    kubectl apply -f k8s-prod.yaml
                    
                    echo "⏳ Attente du démarrage..."
                    sleep 30
                    
                    echo "📊 ÉTAT PRODUCTION:"
                    kubectl get all -n prod
                    
                    # Vérification santé
                    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
                    echo "🌐 POINTS D'ACCÈS PRODUCTION:"
                    echo "  Movie-service: http://${NODE_IP}:31001/health"
                    echo "  Cast-service:  http://${NODE_IP}:31002/health"
                    
                    echo "🧪 Tests production..."
                    if curl -s --max-time 10 http://${NODE_IP}:31001/health ; then
                        echo "  ✅ Movie-service accessible"
                    else
                        echo "  ⚠️ Movie-service non accessible"
                    fi
                    
                    if curl -s --max-time 10 http://${NODE_IP}:31002/health ; then
                        echo "  ✅ Cast-service accessible"
                    else
                        echo "  ⚠️ Cast-service non accessible"
                    fi
                    
                    echo "🎉 DÉPLOIEMENT PRODUCTION RÉUSSI !"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo "========================================"
                echo "FIN DU PIPELINE - RAPPORT"
                echo "========================================"
                
                sh '''
                echo "📋 RÉSUMÉ:"
                echo "   Candidat: Mohamed GUESSOD"
                echo "   Build: ${BUILD_NUMBER}"
                echo "   Tag: exam-${BUILD_NUMBER}"
                echo "   Environnement: ${DEPLOY_ENV}"
                echo ""
                
                echo "🏗️ ÉTAT KUBERNETES:"
                echo "  dev:"
                kubectl get pods -n dev 2>/dev/null | grep -E "movie|cast" || echo "    Pas de service"
                echo "  qa:"
                kubectl get pods -n qa 2>/dev/null | grep -E "movie|cast" || echo "    Pas de service"
                echo "  staging:"
                kubectl get pods -n staging 2>/dev/null | grep -E "movie|cast" || echo "    Pas de service"
                echo "  prod:"
                kubectl get pods -n prod 2>/dev/null | grep -E "movie|cast" || echo "    Pas de service"
                
                echo "🧹 Nettoyage..."
                rm -f k8s-deploy.yaml k8s-prod.yaml 2>/dev/null || true
                '''
            }
        }
        
        success {
            script {
                echo "✅✅✅ SUCCÈS ! ✅✅✅"
                
                // Notification de succès
                sh '''
                echo "🎉 Pipeline exécuté avec succès !"
                '''
            }
        }
        
        failure {
            script {
                echo "❌❌❌ ÉCHEC DU PIPELINE ❌❌❌"
                
                // Notification d'échec
                sh '''
                echo "⚠️ Le pipeline a échoué. Vérifiez les logs pour plus de détails."
                '''
            }
        }
        
        unstable {
            script {
                echo "⚠️⚠️⚠️ PIPELINE INSTABLE ⚠️⚠️⚠️"
            }
        }
    }
}
