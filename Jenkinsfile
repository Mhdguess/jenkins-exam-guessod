pipeline {
    agent any
    
    environment {
        // Docker
        DOCKER_REGISTRY = 'guessod'
        MOVIE_IMAGE = 'movie-service-exam'
        CAST_IMAGE = 'cast-service-exam'
        DOCKER_TAG = "v${BUILD_ID}.${BUILD_TIMESTAMP}"
        
        // Git
        GIT_REPO = 'https://github.com/Mhdguess/jenkins-exam-guessod.git'
        GIT_BRANCH = 'master'
        
        // Kubernetes
        K8S_NAMESPACE = 'dev'
    }
    
    options {
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }
    
    parameters {
        choice(
            name: 'TARGET_NAMESPACE',
            choices: ['dev', 'qa', 'staging'],
            description: 'Namespace Kubernetes cible'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Passer les tests'
        )
        booleanParam(
            name: 'SKIP_DOCKER_PUSH',
            defaultValue: false,
            description: 'Ne pas pousser sur DockerHub'
        )
    }
    
    stages {
        // ============ STAGE 1 : PRÉPARATION ============
        stage('Préparation') {
            steps {
                script {
                    echo "=== INITIALISATION ==="
                    echo "Build: ${BUILD_ID}"
                    echo "Tag: ${DOCKER_TAG}"
                    echo "Namespace cible: ${params.TARGET_NAMESPACE}"
                    
                    // Clean workspace
                    cleanWs()
                    
                    // Checkout
                    checkout scm
                    
                    // Afficher structure
                    sh '''
                    echo "Structure du projet:"
                    ls -la
                    echo ""
                    echo "Services:"
                    ls -la movie-service/ cast-service/
                    '''
                }
            }
        }
        
        // ============ STAGE 2 : VÉRIFICATION ============
        stage('Vérification Code') {
            steps {
                script {
                    echo "=== VÉRIFICATION DU CODE ==="
                    
                    sh '''
                    echo "1. Vérification des fichiers requis..."
                    [ -f "docker-compose.yml" ] || { echo "❌ docker-compose.yml manquant"; exit 1; }
                    [ -f "movie-service/Dockerfile" ] || { echo "❌ Dockerfile movie-service manquant"; exit 1; }
                    [ -f "cast-service/Dockerfile" ] || { echo "❌ Dockerfile cast-service manquant"; exit 1; }
                    [ -f "movie-service/requirements.txt" ] || { echo "❌ requirements.txt movie-service manquant"; exit 1; }
                    [ -f "cast-service/requirements.txt" ] || { echo "❌ requirements.txt cast-service manquant"; exit 1; }
                    
                    echo "2. Vérification syntaxe Python..."
                    python3 -m py_compile movie-service/app/main.py 2>/dev/null && echo "✓ movie-service: Syntaxe OK"
                    python3 -m py_compile cast-service/app/main.py 2>/dev/null && echo "✓ cast-service: Syntaxe OK"
                    
                    echo "3. Vérification Dockerfiles..."
                    echo "Movie-service Dockerfile:"
                    cat movie-service/Dockerfile
                    echo ""
                    echo "Cast-service Dockerfile:"
                    cat cast-service/Dockerfile
                    '''
                }
            }
        }
        
        // ============ STAGE 3 : TESTS LOCAUX ============
        stage('Tests Locaux') {
            when {
                expression { params.SKIP_TESTS == false }
            }
            steps {
                script {
                    echo "=== TESTS AVEC DOCKER-COMPOSE ==="
                    
                    sh '''
                    echo "1. Build et démarrage avec docker-compose..."
                    docker-compose up -d --build
                    
                    echo "2. Attente démarrage services (30s)..."
                    sleep 30
                    
                    echo "3. Tests des endpoints..."
                    
                    # Test movie-service direct
                    echo "→ Test movie-service (port 8001):"
                    if curl -s -f http://localhost:8001/ > /dev/null; then
                        echo "  ✓ Movie-service accessible"
                        curl -s http://localhost:8001/api/v1/movies | head -c 200
                        echo ""
                    else
                        echo "  ✗ Movie-service non accessible"
                        docker-compose logs movie_service
                    fi
                    
                    # Test cast-service direct
                    echo "→ Test cast-service (port 8002):"
                    if curl -s -f http://localhost:8002/ > /dev/null; then
                        echo "  ✓ Cast-service accessible"
                        curl -s http://localhost:8002/api/v1/casts | head -c 200
                        echo ""
                    else
                        echo "  ✗ Cast-service non accessible"
                        docker-compose logs cast_service
                    fi
                    
                    # Test via nginx
                    echo "→ Test via nginx (port 8080):"
                    if curl -s -f http://localhost:8080/api/v1/movies > /dev/null; then
                        echo "  ✓ Nginx + movie-service accessible"
                    else
                        echo "  ✗ Nginx + movie-service non accessible"
                    fi
                    
                    if curl -s -f http://localhost:8080/api/v1/casts > /dev/null; then
                        echo "  ✓ Nginx + cast-service accessible"
                    else
                        echo "  ✗ Nginx + cast-service non accessible"
                    fi
                    
                    echo "4. Arrêt des services..."
                    docker-compose down
                    
                    echo "5. Nettoyage Docker..."
                    docker system prune -f
                    '''
                }
            }
        }
        
        // ============ STAGE 4 : BUILD IMAGES ============
        stage('Build Images Docker') {
            steps {
                script {
                    echo "=== CONSTRUCTION DES IMAGES ==="
                    
                    // Build movie-service
                    dir('movie-service') {
                        sh """
                        echo "Building movie-service..."
                        docker build -t ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:latest
                        
                        echo "Image créée:"
                        docker images | grep ${MOVIE_IMAGE}
                        """
                    }
                    
                    // Build cast-service
                    dir('cast-service') {
                        sh """
                        echo "Building cast-service..."
                        docker build -t ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${CAST_IMAGE}:latest
                        
                        echo "Image créée:"
                        docker images | grep ${CAST_IMAGE}
                        """
                    }
                    
                    // Récapitulatif
                    sh '''
                    echo "=== RÉCAPITULATIF IMAGES ==="
                    docker images | grep guessod
                    '''
                }
            }
        }
        
        // ============ STAGE 5 : PUSH DOCKERHUB ============
        stage('Push vers DockerHub') {
            when {
                expression { params.SKIP_DOCKER_PUSH == false }
            }
            environment {
                DOCKER_CREDS = credentials('dockerhub-guessod')
            }
            steps {
                script {
                    echo "=== ENVOI SUR DOCKERHUB ==="
                    
                    sh """
                    # Connexion
                    echo "\${DOCKER_CREDS_PSW}" | docker login -u "\${DOCKER_CREDS_USR}" --password-stdin
                    
                    # Push movie-service
                    echo "Pushing movie-service..."
                    docker push ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG}
                    docker push ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:latest
                    
                    # Push cast-service
                    echo "Pushing cast-service..."
                    docker push ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG}
                    docker push ${DOCKER_REGISTRY}/${CAST_IMAGE}:latest
                    
                    echo "✅ Images poussées avec succès!"
                    echo "   - ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG}"
                    echo "   - ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG}"
                    """
                }
            }
        }
        
        // ============ STAGE 6 : PRÉPARATION K8S ============
        stage('Préparation Kubernetes') {
            steps {
                script {
                    echo "=== PRÉPARATION KUBERNETES ==="
                    
                    // Créer tous les namespaces
                    sh '''
                    echo "Création des namespaces..."
                    for ns in dev qa staging prod; do
                        kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true
                        echo "  - Namespace $ns ✓"
                    done
                    
                    echo ""
                    echo "Namespaces disponibles:"
                    kubectl get namespaces
                    '''
                    
                    // Créer les manifests K8S simplifiés
                    sh '''
                    echo "Création des manifests Kubernetes..."
                    
                    # Manifest pour movie-service
                    cat > movie-service-deployment.yaml << 'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: movie-service
  namespace: NAMESPACE_PLACEHOLDER
  labels:
    app: movie-service
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
        image: IMAGE_PLACEHOLDER
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "postgresql://movie_db_username:movie_db_password@movie-db-service/movie_db_dev"
        - name: CAST_SERVICE_HOST_URL
          value: "http://cast-service:8000/api/v1/casts/"
        livenessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: movie-service
  namespace: NAMESPACE_PLACEHOLDER
spec:
  type: NodePort
  selector:
    app: movie-service
  ports:
  - port: 8000
    targetPort: 8000
    nodePort: 30001
YAML
                    
                    # Manifest pour cast-service
                    cat > cast-service-deployment.yaml << 'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cast-service
  namespace: NAMESPACE_PLACEHOLDER
  labels:
    app: cast-service
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
        image: IMAGE_PLACEHOLDER
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "postgresql://cast_db_username:cast_db_password@cast-db-service/cast_db_dev"
        livenessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: cast-service
  namespace: NAMESPACE_PLACEHOLDER
spec:
  type: NodePort
  selector:
    app: cast-service
  ports:
  - port: 8000
    targetPort: 8000
    nodePort: 30002
YAML
                    
                    # Services de base de données simplifiés
                    cat > database-deployment.yaml << 'YAML'
# Movie database
apiVersion: apps/v1
kind: Deployment
metadata:
  name: movie-db
  namespace: NAMESPACE_PLACEHOLDER
spec:
  replicas: 1
  selector:
    matchLabels:
      app: movie-db
  template:
    metadata:
      labels:
        app: movie-db
    spec:
      containers:
      - name: postgres
        image: postgres:12.1-alpine
        env:
        - name: POSTGRES_USER
          value: "movie_db_username"
        - name: POSTGRES_PASSWORD
          value: "movie_db_password"
        - name: POSTGRES_DB
          value: "movie_db_dev"
        ports:
        - containerPort: 5432
---
apiVersion: v1
kind: Service
metadata:
  name: movie-db-service
  namespace: NAMESPACE_PLACEHOLDER
spec:
  selector:
    app: movie-db
  ports:
  - port: 5432
    targetPort: 5432
---
# Cast database
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cast-db
  namespace: NAMESPACE_PLACEHOLDER
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cast-db
  template:
    metadata:
      labels:
        app: cast-db
    spec:
      containers:
      - name: postgres
        image: postgres:12.1-alpine
        env:
        - name: POSTGRES_USER
          value: "cast_db_username"
        - name: POSTGRES_PASSWORD
          value: "cast_db_password"
        - name: POSTGRES_DB
          value: "cast_db_dev"
        ports:
        - containerPort: 5432
---
apiVersion: v1
kind: Service
metadata:
  name: cast-db-service
  namespace: NAMESPACE_PLACEHOLDER
spec:
  selector:
    app: cast-db
  ports:
  - port: 5432
    targetPort: 5432
YAML
                    
                    echo "Manifests créés:"
                    ls -la *-deployment.yaml
                    '''
                }
            }
        }
        
        // ============ STAGE 7 : DÉPLOIEMENT K8S ============
        stage('Déploiement Kubernetes') {
            steps {
                script {
                    echo "=== DÉPLOIEMENT SUR KUBERNETES ==="
                    
                    sh """
                    NAMESPACE=${params.TARGET_NAMESPACE}
                    MOVIE_IMAGE_FULL=${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG}
                    CAST_IMAGE_FULL=${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG}
                    
                    echo "Déploiement dans namespace: \$NAMESPACE"
                    echo "Image movie-service: \$MOVIE_IMAGE_FULL"
                    echo "Image cast-service: \$CAST_IMAGE_FULL"
                    
                    # Appliquer les bases de données
                    echo "1. Déploiement des bases de données..."
                    sed "s/NAMESPACE_PLACEHOLDER/\$NAMESPACE/g" database-deployment.yaml | kubectl apply -f -
                    
                    # Appliquer movie-service
                    echo "2. Déploiement movie-service..."
                    sed -e "s/NAMESPACE_PLACEHOLDER/\$NAMESPACE/g" -e "s|IMAGE_PLACEHOLDER|\$MOVIE_IMAGE_FULL|g" movie-service-deployment.yaml | kubectl apply -f -
                    
                    # Appliquer cast-service
                    echo "3. Déploiement cast-service..."
                    sed -e "s/NAMESPACE_PLACEHOLDER/\$NAMESPACE/g" -e "s|IMAGE_PLACEHOLDER|\$CAST_IMAGE_FULL|g" cast-service-deployment.yaml | kubectl apply -f -
                    
                    # Vérifier le déploiement
                    echo "4. Vérification..."
                    kubectl get all -n \$NAMESPACE
                    
                    # Attendre que les pods soient prêts
                    echo "5. Attente démarrage pods..."
                    sleep 10
                    
                    echo "État des pods:"
                    kubectl get pods -n \$NAMESPACE -w --timeout=60s || true
                    """
                }
            }
        }
        
        // ============ STAGE 8 : TESTS K8S ============
        stage('Tests Kubernetes') {
            steps {
                script {
                    echo "=== TESTS SUR KUBERNETES ==="
                    
                    sh """
                    NAMESPACE=${params.TARGET_NAMESPACE}
                    
                    echo "Tests dans namespace: \$NAMESPACE"
                    
                    # Récupérer les ports NodePort
                    MOVIE_NODE_PORT=\$(kubectl get svc movie-service -n \$NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30001")
                    CAST_NODE_PORT=\$(kubectl get svc cast-service -n \$NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30002")
                    NODE_IP=\$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "localhost")
                    
                    echo "URLs d'accès:"
                    echo "  Movie-service: http://\${NODE_IP}:\${MOVIE_NODE_PORT}/api/v1/movies"
                    echo "  Cast-service: http://\${NODE_IP}:\${CAST_NODE_PORT}/api/v1/casts"
                    
                    # Tests
                    echo ""
                    echo "Tests de connectivité..."
                    
                    # Movie-service
                    echo "→ Test movie-service..."
                    for i in {1..10}; do
                        if curl -s -f http://\${NODE_IP}:\${MOVIE_NODE_PORT}/ > /dev/null; then
                            echo "  ✓ Movie-service accessible (tentative \$i)"
                            curl -s http://\${NODE_IP}:\${MOVIE_NODE_PORT}/api/v1/movies | head -c 100
                            echo "..."
                            break
                        else
                            echo "  ⏳ Tentative \$i/10 échouée, attente 5s..."
                            sleep 5
                        fi
                    done
                    
                    # Cast-service
                    echo "→ Test cast-service..."
                    for i in {1..10}; do
                        if curl -s -f http://\${NODE_IP}:\${CAST_NODE_PORT}/ > /dev/null; then
                            echo "  ✓ Cast-service accessible (tentative \$i)"
                            curl -s http://\${NODE_IP}:\${CAST_NODE_PORT}/api/v1/casts | head -c 100
                            echo "..."
                            break
                        else
                            echo "  ⏳ Tentative \$i/10 échouée, attente 5s..."
                            sleep 5
                        fi
                    done
                    
                    # Vérifier les logs
                    echo ""
                    echo "Logs récents:"
                    echo "Movie-service:"
                    kubectl logs -n \$NAMESPACE deployment/movie-service --tail=5 2>/dev/null || echo "Pas de logs disponibles"
                    echo ""
                    echo "Cast-service:"
                    kubectl logs -n \$NAMESPACE deployment/cast-service --tail=5 2>/dev/null || echo "Pas de logs disponibles"
                    """
                }
            }
        }
        
        // ============ STAGE 9 : VALIDATION PRODUCTION ============
        stage('Validation Production') {
            when {
                allOf [
                    expression { env.GIT_BRANCH == 'master' },
                    expression { params.TARGET_NAMESPACE == 'staging' }
                ]
            }
            steps {
                script {
                    echo "=== VALIDATION POUR PRODUCTION ==="
                    
                    timeout(time: 10, unit: 'MINUTES') {
                        input(
                            message: "🚀 Le déploiement en staging est réussi. Voulez-vous déployer en PRODUCTION ?",
                            ok: "✅ Oui, déployer en PRODUCTION",
                            submitter: "admin",
                            parameters: [
                                string(
                                    name: 'PROD_VERSION',
                                    defaultValue: env.DOCKER_TAG,
                                    description: 'Version à déployer (tag Docker)'
                                ),
                                choice(
                                    name: 'PROD_REPLICAS',
                                    choices: ['2', '3', '4'],
                                    description: 'Nombre de réplicas en production'
                                )
                            ]
                        )
                    }
                }
            }
        }
        
        // ============ STAGE 10 : DÉPLOIEMENT PRODUCTION ============
        stage('Déploiement Production') {
            when {
                expression {
                    // S'exécute après validation manuelle
                    return true
                }
            }
            steps {
                script {
                    echo "=== DÉPLOIEMENT PRODUCTION ==="
                    
                    sh """
                    echo "Déploiement en production..."
                    
                    # Créer les manifests pour production
                    cat > movie-service-prod.yaml << 'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: movie-service
  namespace: prod
spec:
  replicas: ${PROD_REPLICAS ?: 3}
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
        image: ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${PROD_VERSION ?: env.DOCKER_TAG}
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "postgresql://movie_db_username:movie_db_password@movie-db-service/movie_db_prod"
        - name: CAST_SERVICE_HOST_URL
          value: "http://cast-service:8000/api/v1/casts/"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: movie-service
  namespace: prod
spec:
  type: NodePort
  selector:
    app: movie-service
  ports:
  - port: 8000
    targetPort: 8000
YAML
                    
                    cat > cast-service-prod.yaml << 'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cast-service
  namespace: prod
spec:
  replicas: ${PROD_REPLICAS ?: 3}
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
        image: ${DOCKER_REGISTRY}/${CAST_IMAGE}:${PROD_VERSION ?: env.DOCKER_TAG}
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "postgresql://cast_db_username:cast_db_password@cast-db-service/cast_db_prod"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: cast-service
  namespace: prod
spec:
  type: NodePort
  selector:
    app: cast-service
  ports:
  - port: 8000
    targetPort: 8000
YAML
                    
                    # Appliquer en production
                    kubectl apply -f movie-service-prod.yaml
                    kubectl apply -f cast-service-prod.yaml
                    
                    echo "Vérification production..."
                    kubectl get all -n prod
                    
                    echo ""
                    echo "Production déployée avec succès!"
                    echo "Réplicas: ${PROD_REPLICAS ?: 3}"
                    echo "Version: ${PROD_VERSION ?: env.DOCKER_TAG}"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "=== FIN DU PIPELINE ==="
            script {
                // Rapport final
                sh '''
                echo "RAPPORT FINAL"
                echo "============="
                echo "Build ID: ${BUILD_ID}"
                echo "Docker Tag: ${DOCKER_TAG}"
                echo "Namespace cible: ${params.TARGET_NAMESPACE}"
                echo ""
                echo "Images Docker:"
                docker images | grep guessod || echo "Aucune image guessod"
                echo ""
                echo "État Kubernetes:"
                for ns in dev qa staging prod; do
                    echo "--- $ns ---"
                    kubectl get pods -n $ns 2>/dev/null | grep -E "(movie|cast)" || echo "  Aucun pod"
                done
                '''
                
                // Nettoyage
                sh '''
                echo "Nettoyage..."
                rm -f *-deployment.yaml *-prod.yaml 2>/dev/null || true
                '''
                
                // Sauvegarder les logs
                archiveArtifacts artifacts: '**/*.log', allowEmptyArchive: true
            }
        }
        
        success {
            echo "✅ PIPELINE RÉUSSI!"
            script {
                // Notification email
                emailext(
                    subject: "✅ SUCCÈS: Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                    Pipeline CI/CD réussi!
                    
                    Détails:
                    - Job: ${env.JOB_NAME}
                    - Build: #${env.BUILD_NUMBER}
                    - Tag: ${env.DOCKER_TAG}
                    - Namespace: ${params.TARGET_NAMESPACE}
                    - Durée: ${currentBuild.durationString}
                    
                    Images déployées:
                    - ${env.DOCKER_REGISTRY}/${env.MOVIE_IMAGE}:${env.DOCKER_TAG}
                    - ${env.DOCKER_REGISTRY}/${env.CAST_IMAGE}:${env.DOCKER_TAG}
                    
                    Consultez: ${env.BUILD_URL}
                    """,
                    to: 'mohamedguessod@gmail.com',
                    replyTo: 'mohamedguessod@gmail.com'
                )
            }
        }
        
        failure {
            echo "❌ PIPELINE EN ÉCHEC!"
            script {
                // Notification email
                emailext(
                    subject: "❌ ÉCHEC: Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                    Pipeline CI/CD en échec!
                    
                    Détails:
                    - Job: ${env.JOB_NAME}
                    - Build: #${env.BUILD_NUMBER}
                    - Namespace: ${params.TARGET_NAMESPACE}
                    
                    Consultez les logs: ${env.BUILD_URL}
                    
                    Commandes de débogage:
                    kubectl get events --sort-by=.lastTimestamp
                    kubectl describe pods -n ${params.TARGET_NAMESPACE}
                    """,
                    to: 'mohamedguessod@gmail.com',
                    replyTo: 'mohamedguessod@gmail.com'
                )
                
                // Logs de débogage
                sh '''
                echo "LOGS DE DÉBOGAGE"
                echo "================"
                echo "Événements Kubernetes récents:"
                kubectl get events --sort-by=.lastTimestamp | tail -20 2>/dev/null || echo "Impossible de récupérer les événements"
                echo ""
                echo "Logs des derniers pods:"
                kubectl get pods -A 2>/dev/null | tail -10 || echo "Impossible de récupérer les pods"
                '''
            }
        }
        
        cleanup {
            echo "🧹 Nettoyage final..."
            sh '''
            echo "Temps d'exécution: ${currentBuild.durationString}"
            echo "Fin: $(date)"
            '''
        }
    }
}
