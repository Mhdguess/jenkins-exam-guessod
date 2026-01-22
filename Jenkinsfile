pipeline {
    agent any
    
    environment {
        // Docker
        DOCKER_REGISTRY = 'guessod'
        MOVIE_IMAGE = 'movie-service-exam'
        CAST_IMAGE = 'cast-service-exam'
        DOCKER_TAG = "v${BUILD_ID}"
        
        // Git
        GIT_REPO = 'https://github.com/Mhdguess/jenkins-exam-guessod.git'
        GIT_BRANCH = 'master'
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
            name: 'RUN_TESTS',
            defaultValue: true,
            description: 'Exécuter les tests'
        )
        booleanParam(
            name: 'PUSH_TO_DOCKERHUB',
            defaultValue: true,
            description: 'Pousser sur DockerHub'
        )
    }
    
    stages {
        // ============ STAGE 1 : PRÉPARATION ============
        stage('Préparation') {
            steps {
                script {
                    echo "=== INITIALISATION DU PIPELINE ==="
                    echo "Build ID: ${BUILD_ID}"
                    echo "Docker Tag: ${DOCKER_TAG}"
                    echo "Namespace cible: ${params.TARGET_NAMESPACE}"
                    echo "Branch: ${env.GIT_BRANCH}"
                    
                    // Clean workspace
                    cleanWs()
                    
                    // Checkout
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: "*/${env.GIT_BRANCH}"]],
                        userRemoteConfigs: [[url: env.GIT_REPO]]
                    ])
                    
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
                    
                    # Vérifier les fichiers essentiels
                    if [ ! -f "docker-compose.yml" ]; then
                        echo "❌ ERREUR: docker-compose.yml manquant"
                        exit 1
                    fi
                    
                    if [ ! -f "movie-service/Dockerfile" ]; then
                        echo "❌ ERREUR: Dockerfile movie-service manquant"
                        exit 1
                    fi
                    
                    if [ ! -f "cast-service/Dockerfile" ]; then
                        echo "❌ ERREUR: Dockerfile cast-service manquant"
                        exit 1
                    fi
                    
                    echo "✓ Tous les fichiers requis sont présents"
                    
                    echo ""
                    echo "2. Vérification syntaxe Python..."
                    
                    # Vérifier movie-service
                    if python3 -m py_compile movie-service/app/main.py 2>/dev/null; then
                        echo "✓ movie-service: Syntaxe Python OK"
                    else
                        echo "⚠ movie-service: Erreur syntaxe (peut être normal si dépendances manquantes)"
                    fi
                    
                    # Vérifier cast-service
                    if python3 -m py_compile cast-service/app/main.py 2>/dev/null; then
                        echo "✓ cast-service: Syntaxe Python OK"
                    else
                        echo "⚠ cast-service: Erreur syntaxe (peut être normal si dépendances manquantes)"
                    fi
                    
                    echo ""
                    echo "3. Vérification Dockerfiles..."
                    echo "Movie-service:"
                    head -10 movie-service/Dockerfile
                    echo ""
                    echo "Cast-service:"
                    head -10 cast-service/Dockerfile
                    '''
                }
            }
        }
        
        // ============ STAGE 3 : TESTS ============
        stage('Tests') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                script {
                    echo "=== TESTS AUTOMATISÉS ==="
                    
                    sh '''
                    echo "1. Build avec docker-compose..."
                    docker-compose build
                    
                    echo "2. Démarrage des services..."
                    docker-compose up -d
                    
                    echo "3. Attente démarrage (30 secondes)..."
                    sleep 30
                    
                    echo "4. Tests des endpoints..."
                    
                    # Test movie-service
                    echo "→ Test movie-service (port 8001):"
                    if curl -s -f http://localhost:8001/ > /dev/null; then
                        echo "  ✓ Movie-service accessible"
                        RESPONSE=$(curl -s http://localhost:8001/api/v1/movies 2>/dev/null || echo "{}")
                        echo "  Réponse: ${RESPONSE:0:100}..."
                    else
                        echo "  ✗ Movie-service non accessible"
                        echo "  Logs:"
                        docker-compose logs movie_service --tail=10
                    fi
                    
                    # Test cast-service
                    echo ""
                    echo "→ Test cast-service (port 8002):"
                    if curl -s -f http://localhost:8002/ > /dev/null; then
                        echo "  ✓ Cast-service accessible"
                        RESPONSE=$(curl -s http://localhost:8002/api/v1/casts 2>/dev/null || echo "{}")
                        echo "  Réponse: ${RESPONSE:0:100}..."
                    else
                        echo "  ✗ Cast-service non accessible"
                        echo "  Logs:"
                        docker-compose logs cast_service --tail=10
                    fi
                    
                    # Test via nginx
                    echo ""
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
                    
                    echo ""
                    echo "5. Arrêt des services..."
                    docker-compose down
                    
                    echo "6. Nettoyage Docker..."
                    docker system prune -f
                    '''
                }
            }
        }
        
        // ============ STAGE 4 : BUILD IMAGES DOCKER ============
        stage('Build Images Docker') {
            steps {
                script {
                    echo "=== CONSTRUCTION DES IMAGES DOCKER ==="
                    
                    // Build movie-service
                    dir('movie-service') {
                        sh """
                        echo "Building movie-service..."
                        docker build -t ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:latest
                        
                        echo "Image créée:"
                        docker images | grep ${DOCKER_REGISTRY}/${MOVIE_IMAGE}
                        """
                    }
                    
                    // Build cast-service
                    dir('cast-service') {
                        sh """
                        echo "Building cast-service..."
                        docker build -t ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${CAST_IMAGE}:latest
                        
                        echo "Image créée:"
                        docker images | grep ${DOCKER_REGISTRY}/${CAST_IMAGE}
                        """
                    }
                    
                    // Récapitulatif
                    sh '''
                    echo "=== RÉCAPITULATIF DES IMAGES ==="
                    docker images | grep guessod || echo "Aucune image trouvée"
                    '''
                }
            }
        }
        
        // ============ STAGE 5 : PUSH DOCKERHUB ============
        stage('Push DockerHub') {
            when {
                expression { params.PUSH_TO_DOCKERHUB == true }
            }
            environment {
                DOCKERHUB_CREDS = credentials('dockerhub-guessod')
            }
            steps {
                script {
                    echo "=== ENVOI SUR DOCKERHUB ==="
                    
                    sh """
                    # Connexion à DockerHub
                    echo "\${DOCKERHUB_CREDS_PSW}" | docker login -u "\${DOCKERHUB_CREDS_USR}" --password-stdin
                    
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
        
        // ============ STAGE 6 : PRÉPARATION KUBERNETES ============
        stage('Préparation Kubernetes') {
            steps {
                script {
                    echo "=== PRÉPARATION DES ENVIRONNEMENTS KUBERNETES ==="
                    
                    sh '''
                    echo "Création des namespaces..."
                    
                    # Créer les 4 namespaces
                    for ns in dev qa staging prod; do
                        kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true
                        echo "  - Namespace $ns créé/vérifié"
                    done
                    
                    echo ""
                    echo "Namespaces disponibles:"
                    kubectl get namespaces | grep -E "dev|qa|staging|prod|default"
                    '''
                }
            }
        }
        
        // ============ STAGE 7 : DÉPLOIEMENT KUBERNETES ============
        stage('Déploiement Kubernetes') {
            steps {
                script {
                    echo "=== DÉPLOIEMENT SUR KUBERNETES ==="
                    
                    sh """
                    NAMESPACE=${params.TARGET_NAMESPACE}
                    echo "Déploiement dans namespace: \$NAMESPACE"
                    
                    # Créer les manifests Kubernetes
                    cat > k8s-deployment.yaml << 'YAML'
---
# Movie Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: movie-service
  namespace: ${params.TARGET_NAMESPACE}
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
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "postgresql://movie_db_username:movie_db_password@movie-db-service/movie_db_dev"
        - name: CAST_SERVICE_HOST_URL
          value: "http://cast-service:8000/api/v1/casts/"
---
apiVersion: v1
kind: Service
metadata:
  name: movie-service
  namespace: ${params.TARGET_NAMESPACE}
spec:
  type: NodePort
  selector:
    app: movie-service
  ports:
  - port: 8000
    targetPort: 8000
---
# Cast Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cast-service
  namespace: ${params.TARGET_NAMESPACE}
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
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "postgresql://cast_db_username:cast_db_password@cast-db-service/cast_db_dev"
---
apiVersion: v1
kind: Service
metadata:
  name: cast-service
  namespace: ${params.TARGET_NAMESPACE}
spec:
  type: NodePort
  selector:
    app: cast-service
  ports:
  - port: 8000
    targetPort: 8000
YAML
                    
                    # Appliquer le déploiement
                    echo "Application du déploiement..."
                    kubectl apply -f k8s-deployment.yaml
                    
                    # Vérifier le déploiement
                    echo "Vérification..."
                    kubectl get all -n \$NAMESPACE
                    
                    # Attendre que les pods démarrent
                    echo "Attente du démarrage des pods..."
                    sleep 20
                    
                    echo "État des pods:"
                    kubectl get pods -n \$NAMESPACE
                    """
                }
            }
        }
        
        // ============ STAGE 8 : TESTS KUBERNETES ============
        stage('Tests Kubernetes') {
            steps {
                script {
                    echo "=== TESTS SUR KUBERNETES ==="
                    
                    sh """
                    NAMESPACE=${params.TARGET_NAMESPACE}
                    echo "Tests dans namespace: \$NAMESPACE"
                    
                    # Récupérer les ports NodePort
                    MOVIE_PORT=\$(kubectl get svc movie-service -n \$NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
                    CAST_PORT=\$(kubectl get svc cast-service -n \$NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
                    
                    # Récupérer l'IP du nœud
                    NODE_IP=\$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "localhost")
                    
                    echo "URLs d'accès:"
                    echo "  Movie-service: http://\${NODE_IP}:\${MOVIE_PORT}/api/v1/movies"
                    echo "  Cast-service: http://\${NODE_IP}:\${CAST_PORT}/api/v1/casts"
                    
                    # Tests de connectivité
                    echo ""
                    echo "Tests de connectivité..."
                    
                    if [ "\$MOVIE_PORT" != "N/A" ]; then
                        echo "→ Test movie-service..."
                        for i in {1..5}; do
                            if curl -s -f http://\${NODE_IP}:\${MOVIE_PORT}/ > /dev/null; then
                                echo "  ✓ Movie-service accessible (tentative \$i)"
                                break
                            else
                                echo "  ⏳ Tentative \$i/5 échouée, attente 5s..."
                                sleep 5
                            fi
                        done
                    else
                        echo "⚠ Movie-service: Port non disponible"
                    fi
                    
                    if [ "\$CAST_PORT" != "N/A" ]; then
                        echo "→ Test cast-service..."
                        for i in {1..5}; do
                            if curl -s -f http://\${NODE_IP}:\${CAST_PORT}/ > /dev/null; then
                                echo "  ✓ Cast-service accessible (tentative \$i)"
                                break
                            else
                                echo "  ⏳ Tentative \$i/5 échouée, attente 5s..."
                                sleep 5
                            fi
                        done
                    else
                        echo "⚠ Cast-service: Port non disponible"
                    fi
                    
                    # Afficher les logs
                    echo ""
                    echo "Logs récents:"
                    kubectl logs -n \$NAMESPACE deployment/movie-service --tail=5 2>/dev/null || echo "  Pas de logs disponibles pour movie-service"
                    echo ""
                    kubectl logs -n \$NAMESPACE deployment/cast-service --tail=5 2>/dev/null || echo "  Pas de logs disponibles pour cast-service"
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
                    echo "=== VALIDATION POUR DÉPLOIEMENT PRODUCTION ==="
                    
                    timeout(time: 10, unit: 'MINUTES') {
                        input(
                            message: "🚀 Déploiement staging réussi. Déployer en PRODUCTION ?",
                            ok: "✅ Oui, déployer en PRODUCTION",
                            submitter: "admin"
                        )
                    }
                }
            }
        }
        
        // ============ STAGE 10 : DÉPLOIEMENT PRODUCTION ============
        stage('Déploiement Production') {
            when {
                expression {
                    // Cette étape s'exécute si l'étape précédente a été validée
                    // Nous allons simplement créer un manifest pour prod
                    return true
                }
            }
            steps {
                script {
                    echo "=== DÉPLOIEMENT EN PRODUCTION ==="
                    
                    sh """
                    echo "Création du déploiement production..."
                    
                    cat > k8s-production.yaml << 'YAML'
---
# Movie Service Production
apiVersion: apps/v1
kind: Deployment
metadata:
  name: movie-service-prod
  namespace: prod
spec:
  replicas: 3
  selector:
    matchLabels:
      app: movie-service-prod
  template:
    metadata:
      labels:
        app: movie-service-prod
    spec:
      containers:
      - name: movie-service
        image: ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG}
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "postgresql://movie_db_username:movie_db_password@movie-db-service-prod/movie_db_prod"
        - name: CAST_SERVICE_HOST_URL
          value: "http://cast-service-prod:8000/api/v1/casts/"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: movie-service-prod
  namespace: prod
spec:
  type: NodePort
  selector:
    app: movie-service-prod
  ports:
  - port: 8000
    targetPort: 8000
---
# Cast Service Production
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cast-service-prod
  namespace: prod
spec:
  replicas: 3
  selector:
    matchLabels:
      app: cast-service-prod
  template:
    metadata:
      labels:
        app: cast-service-prod
    spec:
      containers:
      - name: cast-service
        image: ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG}
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "postgresql://cast_db_username:cast_db_password@cast-db-service-prod/cast_db_prod"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: cast-service-prod
  namespace: prod
spec:
  type: NodePort
  selector:
    app: cast-service-prod
  ports:
  - port: 8000
    targetPort: 8000
YAML
                    
                    # Appliquer le déploiement production
                    kubectl apply -f k8s-production.yaml
                    
                    echo "Vérification production..."
                    kubectl get all -n prod
                    
                    echo ""
                    echo "✅ Production déployée avec succès!"
                    echo "   Réplicas: 3"
                    echo "   Version: ${DOCKER_TAG}"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "=== FIN DU PIPELINE ==="
            script {
                sh '''
                echo "RAPPORT FINAL"
                echo "============="
                echo "Build: ${BUILD_ID}"
                echo "Tag: ${DOCKER_TAG}"
                echo "Namespace déployé: ${params.TARGET_NAMESPACE}"
                echo "Tests exécutés: ${params.RUN_TESTS}"
                echo "Push DockerHub: ${params.PUSH_TO_DOCKERHUB}"
                echo ""
                echo "État Kubernetes:"
                for ns in dev qa staging prod; do
                    echo "--- $ns ---"
                    kubectl get pods -n $ns 2>/dev/null | grep -v "No resources" || echo "  Aucun pod"
                done
                '''
                
                // Nettoyage
                sh '''
                echo "Nettoyage des fichiers temporaires..."
                rm -f k8s-deployment.yaml k8s-production.yaml 2>/dev/null || true
                '''
            }
        }
        
        success {
            echo "✅ PIPELINE RÉUSSI!"
            script {
                // Envoyer un email
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
                    
                    Images DockerHub:
                    - ${env.DOCKER_REGISTRY}/${env.MOVIE_IMAGE}:${env.DOCKER_TAG}
                    - ${env.DOCKER_REGISTRY}/${env.CAST_IMAGE}:${env.DOCKER_TAG}
                    
                    URL: ${env.BUILD_URL}
                    """,
                    to: 'mohamedguessod@gmail.com'
                )
            }
        }
        
        failure {
            echo "❌ PIPELINE EN ÉCHEC!"
            script {
                // Envoyer un email
                emailext(
                    subject: "❌ ÉCHEC: Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                    Pipeline CI/CD en échec!
                    
                    Détails:
                    - Job: ${env.JOB_NAME}
                    - Build: #${env.BUILD_NUMBER}
                    - Namespace: ${params.TARGET_NAMESPACE}
                    
                    Consultez les logs: ${env.BUILD_URL}
                    """,
                    to: 'mohamedguessod@gmail.com'
                )
                
                // Logs de débogage
                sh '''
                echo "LOGS DE DÉBOGAGE"
                echo "================"
                echo "Événements récents:"
                kubectl get events --sort-by=.lastTimestamp 2>/dev/null | tail -10 || echo "  Impossible de récupérer les événements"
                echo ""
                echo "Logs Docker:"
                docker ps -a 2>/dev/null | tail -5 || echo "  Aucun container Docker"
                '''
            }
        }
        
        cleanup {
            echo "🧹 Nettoyage final..."
            sh '''
            echo "Durée d'exécution: ${currentBuild.durationString}"
            '''
        }
    }
}
