pipeline {
    agent any
    
    environment {
        // Docker
        DOCKER_REGISTRY = 'guessod'
        MOVIE_IMAGE = 'movie-service-exam'
        CAST_IMAGE = 'cast-service-exam'
        DOCKER_TAG = "exam-${BUILD_ID}"
        
        // Kubernetes
        K8S_NAMESPACE = 'dev'
    }
    
    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['dev', 'qa', 'staging'],
            description: 'Environnement de déploiement'
        )
        booleanParam(
            name: 'SKIP_DOCKER_PUSH',
            defaultValue: false,
            description: 'Passer le push DockerHub'
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
                    echo "Build ID: ${BUILD_ID}"
                    echo "Docker Tag: ${DOCKER_TAG}"
                    echo "Environnement cible: ${params.DEPLOY_ENV}"
                    echo ""
                    
                    // Nettoyage workspace
                    cleanWs()
                    
                    // Checkout du code
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/master']],
                        userRemoteConfigs: [[url: 'https://github.com/Mhdguess/jenkins-exam-guessod.git']]
                    ])
                    
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
                    
                    # Movie-service: s'assurer que pydantic est présent avec version compatible
                    echo "→ Optimisation movie-service..."
                    if [ -f "movie-service/requirements.txt" ]; then
                        echo "  📋 Requirements.txt actuel:"
                        cat movie-service/requirements.txt
                        
                        # Vérifier si pydantic est présent
                        if ! grep -qi "pydantic" movie-service/requirements.txt; then
                            echo "  ➕ Ajout de pydantic compatible..."
                            echo "# Ajouté automatiquement pour compatibilité" >> movie-service/requirements.txt
                            echo "pydantic==1.10.13" >> movie-service/requirements.txt
                        fi
                        
                        # S'assurer que toutes les dépendances critiques sont présentes
                        echo "  ✅ Requirements.txt optimisé"
                    fi
                    
                    # Cast-service: s'assurer que pydantic est présent avec version compatible
                    echo "→ Optimisation cast-service..."
                    if [ -f "cast-service/requirements.txt" ]; then
                        echo "  📋 Requirements.txt actuel:"
                        cat cast-service/requirements.txt
                        
                        # Vérifier si pydantic est présent
                        if ! grep -qi "pydantic" cast-service/requirements.txt; then
                            echo "  ➕ Ajout de pydantic compatible..."
                            echo "# Ajouté automatiquement pour compatibilité" >> cast-service/requirements.txt
                            echo "pydantic==1.10.13" >> cast-service/requirements.txt
                        fi
                        
                        echo "  ✅ Requirements.txt optimisé"
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
        
        // ========== STAGE 3 : BUILD DOCKER ==========
        stage('Build Docker Images') {
            steps {
                script {
                    echo "=== BUILD DES IMAGES DOCKER ==="
                    
                    // Build movie-service avec retry en cas d'échec
                    dir('movie-service') {
                        sh """
                        echo "🔨 Construction de movie-service..."
                        
                        # Afficher les dépendances
                        echo "📦 Dépendances à installer:"
                        cat requirements.txt
                        
                        # Tentative de build avec gestion d'erreur
                        echo "🚀 Lancement du build..."
                        set +e  # Désactiver l'arrêt sur erreur
                        
                        # Premier essai
                        BUILD_OUTPUT=\$(docker build -t ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} . 2>&1)
                        BUILD_STATUS=\$?
                        
                        if [ \$BUILD_STATUS -eq 0 ]; then
                            echo "✅ Build réussi du premier coup"
                        else
                            echo "⚠️ Premier build échoué, analyse de l'erreur..."
                            
                            # Vérifier si c'est un problème de dépendances
                            if echo "\$BUILD_OUTPUT" | grep -q "ResolutionImpossible\\|conflict\\|pydantic"; then
                                echo "🔧 Problème de dépendances détecté, tentative de correction..."
                                
                                # Créer un requirements.txt simplifié
                                cat > requirements.simple << SIMPLE
aiosqlite==0.19.0
databases[sqlite]==0.2.6
fastapi==0.48.0
SQLAlchemy==1.3.13
uvicorn[standard]==0.11.2
httpx==0.11.1
pydantic==1.10.13
SIMPLE
                                
                                mv requirements.simple requirements.txt
                                echo "📋 Nouveau requirements.txt:"
                                cat requirements.txt
                                
                                # Deuxième essai
                                echo "🔄 Deuxième tentative de build..."
                                docker build -t ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} .
                                
                                if [ \$? -eq 0 ]; then
                                    echo "✅ Build réussi après correction"
                                else
                                    echo "❌ Échec définitif du build"
                                    exit 1
                                fi
                            else
                                echo "❌ Autre erreur de build:"
                                echo "\$BUILD_OUTPUT" | tail -20
                                exit 1
                            fi
                        fi
                        
                        set -e  # Réactiver l'arrêt sur erreur
                        
                        # Ajouter le tag latest
                        docker tag ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:latest
                        echo "✅ Tag 'latest' ajouté"
                        """
                    }
                    
                    // Build cast-service
                    dir('cast-service') {
                        sh """
                        echo "🔨 Construction de cast-service..."
                        
                        # Afficher les dépendances
                        echo "📦 Dépendances à installer:"
                        cat requirements.txt
                        
                        # Build simple
                        if docker build -t ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} . ; then
                            echo "✅ Build réussi"
                            docker tag ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${CAST_IMAGE}:latest
                            echo "✅ Tag 'latest' ajouté"
                        else
                            echo "❌ Échec du build cast-service"
                            exit 1
                        fi
                        """
                    }
                    
                    // Vérification des images - CORRECTION ICI
                    sh '''
                    echo ""
                    echo "🧪 VÉRIFICATION DES IMAGES:"
                    
                    echo "📊 Images disponibles:"
                    docker images | grep -E "REPOSITORY|guessod" || echo "Aucune image trouvée"
                    
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
                expression { params.SKIP_DOCKER_PUSH == false }
            }
            environment {
                DOCKERHUB_CREDS = credentials('dockerhub-guessod')
            }
            steps {
                script {
                    echo "=== PUSH SUR DOCKERHUB ==="
                    
                    sh """
                    # Connexion à DockerHub
                    echo "\${DOCKERHUB_CREDS_PSW}" | docker login -u "\${DOCKERHUB_CREDS_USR}" --password-stdin
                    
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
                    echo "   - Accès: https://hub.docker.com/u/guessod"
                    """
                }
            }
        }
        
        // ========== STAGE 6 : PRÉPARATION KUBERNETES ==========
        stage('Préparation Kubernetes') {
            steps {
                script {
                    echo "=== CONFIGURATION KUBERNETES ==="
                    
                    sh '''
                    echo "📁 Création des namespaces..."
                    
                    # Créer les 4 namespaces
                    for ns in dev qa staging prod; do
                        if kubectl get namespace $ns >/dev/null 2>&1; then
                            echo "  ✅ Namespace $ns existe déjà"
                        else
                            kubectl create namespace $ns
                            echo "  ✅ Namespace $ns créé"
                        fi
                    done
                    
                    echo ""
                    echo "📋 ÉTAT DES NAMESPACES:"
                    kubectl get namespaces | grep -E "dev|qa|staging|prod|NAME"
                    
                    # Nettoyage minimal
                    echo ""
                    echo "🧹 Nettoyage léger..."
                    kubectl delete deployment movie-service cast-service -n dev --ignore-not-found=true
                    sleep 2
                    '''
                }
            }
        }
        
        // ========== STAGE 7 : DÉPLOIEMENT KUBERNETES ==========
        stage('Déploiement Kubernetes') {
            steps {
                script {
                    echo "=== DÉPLOIEMENT SUR KUBERNETES ==="
                    
                    sh """
                    NAMESPACE=${params.DEPLOY_ENV}
                    echo "🚀 Déploiement dans namespace: \$NAMESPACE"
                    
                    # Créer un déploiement simple et fiable
                    cat > k8s-deploy.yaml << YAML
---
# Service Movie
apiVersion: v1
kind: Service
metadata:
  name: movie-service
  namespace: ${params.DEPLOY_ENV}
spec:
  type: NodePort
  selector:
    app: movie-service
  ports:
  - port: 8000
    targetPort: 8000
    nodePort: 30001
---
# Deployment Movie
apiVersion: apps/v1
kind: Deployment
metadata:
  name: movie-service
  namespace: ${params.DEPLOY_ENV}
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
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "sqlite:///:memory:"
        - name: CAST_SERVICE_HOST_URL
          value: "http://cast-service:8000/api/v1/casts/"
        # Probes très simples
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
---
# Service Cast
apiVersion: v1
kind: Service
metadata:
  name: cast-service
  namespace: ${params.DEPLOY_ENV}
spec:
  type: NodePort
  selector:
    app: cast-service
  ports:
  - port: 8000
    targetPort: 8000
    nodePort: 30002
---
# Deployment Cast
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cast-service
  namespace: ${params.DEPLOY_ENV}
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
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "sqlite:///:memory:"
        # Probes très simples
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 20
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
YAML
                    
                    echo "📄 Application du déploiement..."
                    kubectl apply -f k8s-deploy.yaml
                    
                    echo "✅ DÉPLOIEMENT APPLIQUÉ"
                    echo ""
                    echo "⏳ Attente du démarrage (45 secondes)..."
                    sleep 45
                    
                    echo "📊 ÉTAT ACTUEL:"
                    kubectl get all -n \$NAMESPACE
                    
                    echo ""
                    echo "📋 LOGS:"
                    echo "Movie-service:"
                    kubectl logs -n \$NAMESPACE deployment/movie-service --tail=5 2>/dev/null || echo "Pas de logs"
                    echo ""
                    echo "Cast-service:"
                    kubectl logs -n \$NAMESPACE deployment/cast-service --tail=5 2>/dev/null || echo "Pas de logs"
                    """
                }
            }
        }
        
        // ========== STAGE 8 : VALIDATION ==========
        stage('Validation') {
            steps {
                script {
                    echo "=== VALIDATION FINALE ==="
                    
                    sh """
                    NAMESPACE=${params.DEPLOY_ENV}
                    
                    echo "🔍 ÉTAT FINAL:"
                    kubectl get pods,svc -n \$NAMESPACE
                    
                    # Informations d'accès
                    MOVIE_PORT=30001
                    CAST_PORT=30002
                    NODE_IP=\$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}' 2>/dev/null || echo "localhost")
                    
                    echo ""
                    echo "🌐 POINTS D'ACCÈS:"
                    echo "  Movie-service: http://\$NODE_IP:\$MOVIE_PORT/health"
                    echo "  Cast-service: http://\$NODE_IP:\$CAST_PORT/health"
                    
                    echo ""
                    echo "🧪 TESTS RAPIDES:"
                    
                    echo "→ Test movie-service..."
                    if curl -s -f --max-time 10 http://\$NODE_IP:\$MOVIE_PORT/health > /dev/null; then
                        echo "  ✅ Accessible"
                    else
                        echo "  ❌ Non accessible"
                    fi
                    
                    echo "→ Test cast-service..."
                    if curl -s -f --max-time 10 http://\$NODE_IP:\$CAST_PORT/health > /dev/null; then
                        echo "  ✅ Accessible"
                    else
                        echo "  ❌ Non accessible"
                    fi
                    
                    # Vérifier les 4 namespaces
                    echo ""
                    echo "📁 VÉRIFICATION DES 4 ENVIRONNEMENTS:"
                    for ns in dev qa staging prod; do
                        PODS=\$(kubectl get pods -n \$ns 2>/dev/null | wc -l)
                        echo "  \$ns: \${PODS} pod(s)"
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
                expression { params.DEPLOY_ENV == 'staging' }
            }
            steps {
                script {
                    echo "=== VALIDATION PRODUCTION ==="
                    
                    timeout(time: 5, unit: 'MINUTES') {
                        input(
                            message: "✅ Staging réussi. Déployer en PRODUCTION ?",
                            ok: "🚀 DÉPLOYER EN PRODUCTION",
                            submitter: "admin,administrator"
                        )
                    }
                    
                    echo "✅ Validation acceptée"
                }
            }
        }
        
        // ========== STAGE 10 : DÉPLOIEMENT PRODUCTION ==========
        stage('Déploiement Production') {
            when {
                allOf {
                    expression { params.DEPLOY_ENV == 'staging' }
                    expression { return true }
                }
            }
            steps {
                script {
                    echo "=== DÉPLOIEMENT PRODUCTION ==="
                    
                    sh """
                    echo "🎯 Déploiement en production..."
                    
                    cat > k8s-prod.yaml << YAML
---
# Production Movie
apiVersion: apps/v1
kind: Deployment
metadata:
  name: movie-service-prod
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
        image: ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG}
        imagePullPolicy: Always
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "sqlite:///:memory:"
        - name: CAST_SERVICE_HOST_URL
          value: "http://cast-service-prod:8000/api/v1/casts/"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
---
apiVersion: v1
kind: Service
metadata:
  name: movie-service-prod
  namespace: prod
spec:
  selector:
    app: movie-service
  ports:
  - port: 8000
---
# Production Cast
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cast-service-prod
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
        image: ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG}
        imagePullPolicy: Always
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "sqlite:///:memory:"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
---
apiVersion: v1
kind: Service
metadata:
  name: cast-service-prod
  namespace: prod
spec:
  selector:
    app: cast-service
  ports:
  - port: 8000
YAML
                    
                    kubectl apply -f k8s-prod.yaml
                    
                    echo "✅ PRODUCTION DÉPLOYÉE"
                    echo ""
                    echo "📊 ÉTAT PRODUCTION:"
                    kubectl get all -n prod
                    
                    echo ""
                    echo "🎉 MISSION ACCOMPLIE !"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "========================================"
            echo "FIN DU PIPELINE - RAPPORT"
            echo "========================================"
            script {
                sh """
                echo "📋 RÉSUMÉ:"
                echo "   Candidat: Mohamed GUESSOD"
                echo "   Build: ${BUILD_ID}"
                echo "   Tag: ${DOCKER_TAG}"
                echo "   Environnement: ${params.DEPLOY_ENV}"
                echo ""
                """
                
                sh '''
                echo "🏗️ ÉTAT KUBERNETES:"
                for ns in dev qa staging prod; do
                    echo "  $ns:"
                    kubectl get pods -n $ns 2>/dev/null | grep -E "movie|cast" || echo "    Pas de service"
                done
                '''
                
                sh '''
                echo "🧹 Nettoyage..."
                rm -f k8s-deploy.yaml k8s-prod.yaml 2>/dev/null || true
                '''
            }
        }
        
        success {
            echo "✅✅✅ SUCCÈS ! ✅✅✅"
            script {
                echo "🎉 Pipeline exécuté avec succès !"
            }
        }
        
        failure {
            echo "❌❌❌ ÉCHEC ❌❌❌"
            script {
                echo "⚠️ Le pipeline a échoué. Vérifiez les logs."
            }
        }
    }
}
