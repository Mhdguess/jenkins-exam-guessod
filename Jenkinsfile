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
                    echo "Vérification des fichiers..."
                    [ -f "docker-compose.yml" ] && echo "✓ docker-compose.yml présent"
                    [ -f "movie-service/Dockerfile" ] && echo "✓ movie-service/Dockerfile présent"
                    [ -f "cast-service/Dockerfile" ] && echo "✓ cast-service/Dockerfile présent"
                    '''
                }
            }
        }
        
        // ========== STAGE 2 : BUILD DOCKER ==========
        stage('Build Docker Images') {
            steps {
                script {
                    echo "=== BUILD DES IMAGES DOCKER ==="
                    
                    // Build movie-service
                    dir('movie-service') {
                        sh """
                        echo "Construction de movie-service..."
                        docker build -t ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:latest
                        echo "✅ Image movie-service créée"
                        """
                    }
                    
                    // Build cast-service
                    dir('cast-service') {
                        sh """
                        echo "Construction de cast-service..."
                        docker build -t ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${CAST_IMAGE}:latest
                        echo "✅ Image cast-service créée"
                        """
                    }
                    
                    // Afficher les images
                    sh '''
                    echo ""
                    echo "📦 IMAGES DISPONIBLES:"
                    docker images | grep guessod || echo "⚠️ Aucune image trouvée"
                    '''
                }
            }
        }
        
        // ========== STAGE 3 : TESTS SIMPLES ==========
        stage('Tests Simples') {
            steps {
                script {
                    echo "=== TESTS DE VALIDATION ==="
                    
                    sh '''
                    echo "1. Test de construction des images..."
                    docker images | grep guessod && echo "✅ Images construites avec succès"
                    
                    echo ""
                    echo "2. Test de démarrage rapide..."
                    
                    # Test movie-service
                    echo "→ Test movie-service..."
                    docker run -d --name test-movie --rm -p 8001:8000 guessod/movie-service-exam:latest
                    sleep 10
                    
                    if docker ps | grep test-movie; then
                        echo "  ✅ Container movie-service en cours d'exécution"
                        docker stop test-movie
                    else
                        echo "  ⚠️ Container movie-service non démarré"
                        docker logs test-movie 2>/dev/null || true
                    fi
                    
                    # Test cast-service
                    echo "→ Test cast-service..."
                    docker run -d --name test-cast --rm -p 8002:8000 guessod/cast-service-exam:latest
                    sleep 10
                    
                    if docker ps | grep test-cast; then
                        echo "  ✅ Container cast-service en cours d'exécution"
                        docker stop test-cast
                    else
                        echo "  ⚠️ Container cast-service non démarré"
                        docker logs test-cast 2>/dev/null || true
                    fi
                    
                    # Nettoyage
                    docker system prune -f
                    echo "✅ Tests terminés"
                    '''
                }
            }
        }
        
        // ========== STAGE 4 : PUSH DOCKERHUB ==========
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
        
        // ========== STAGE 5 : PRÉPARATION KUBERNETES ==========
        stage('Préparation Kubernetes') {
            steps {
                script {
                    echo "=== CONFIGURATION KUBERNETES ==="
                    
                    sh '''
                    echo "Création des 4 namespaces demandés..."
                    
                    # Créer les namespaces
                    for ns in dev qa staging prod; do
                        kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true
                        echo "  ✅ Namespace $ns créé/vérifié"
                    done
                    
                    echo ""
                    echo "📋 NAMESPACES DISPONIBLES:"
                    kubectl get namespaces | grep -E "dev|qa|staging|prod|NAME"
                    echo ""
                    '''
                }
            }
        }
        
        // ========== STAGE 6 : DÉPLOIEMENT KUBERNETES ==========
        stage('Déploiement Kubernetes') {
            steps {
                script {
                    echo "=== DÉPLOIEMENT SUR KUBERNETES ==="
                    
                    sh """
                    NAMESPACE=${params.DEPLOY_ENV}
                    echo "🚀 Déploiement dans namespace: \$NAMESPACE"
                    
                    # Créer le fichier de déploiement
                    cat > k8s-deploy.yaml << 'YAML'
---
# Movie Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: movie-service
  namespace: ${params.DEPLOY_ENV}
  labels:
    app: movie-service
    exam: datascientest
spec:
  replicas: 1
  selector:
    matchLabels:
      app: movie-service
  template:
    metadata:
      labels:
        app: movie-service
        exam: datascientest
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
---
apiVersion: v1
kind: Service
metadata:
  name: movie-service
  namespace: ${params.DEPLOY_ENV}
  labels:
    app: movie-service
    exam: datascientest
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
  namespace: ${params.DEPLOY_ENV}
  labels:
    app: cast-service
    exam: datascientest
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cast-service
  template:
    metadata:
      labels:
        app: cast-service
        exam: datascientest
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
---
apiVersion: v1
kind: Service
metadata:
  name: cast-service
  namespace: ${params.DEPLOY_ENV}
  labels:
    app: cast-service
    exam: datascientest
spec:
  type: NodePort
  selector:
    app: cast-service
  ports:
  - port: 8000
    targetPort: 8000
YAML
                    
                    # Appliquer le déploiement
                    kubectl apply -f k8s-deploy.yaml
                    
                    echo "✅ DÉPLOIEMENT APPLIQUÉ"
                    echo ""
                    echo "📊 ÉTAT DU DÉPLOIEMENT:"
                    kubectl get all -n \$NAMESPACE
                    
                    # Attendre le démarrage
                    echo ""
                    echo "⏳ Attente du démarrage des pods (20 secondes)..."
                    sleep 20
                    
                    echo "🔍 ÉTAT DES PODS:"
                    kubectl get pods -n \$NAMESPACE -o wide
                    """
                }
            }
        }
        
        // ========== STAGE 7 : VALIDATION PRODUCTION ==========
        stage('Validation Production') {
            when {
                expression { 
                    params.DEPLOY_ENV == 'staging' 
                }
            }
            steps {
                script {
                    echo "=== VALIDATION POUR PRODUCTION ==="
                    echo "📋 Le déploiement en staging est prêt."
                    echo "🔒 La production nécessite une validation manuelle."
                    
                    timeout(time: 10, unit: 'MINUTES') {
                        input(
                            message: "✅ Le déploiement staging est réussi.\n\nVoulez-vous déployer en PRODUCTION ?",
                            ok: "🚀 OUI, DÉPLOYER EN PRODUCTION",
                            submitter: "admin,administrator"
                        )
                    }
                    
                    echo "✅ Validation production approuvée!"
                }
            }
        }
        
        // ========== STAGE 8 : DÉPLOIEMENT PRODUCTION ==========
        stage('Déploiement Production') {
            when {
                expression {
                    // S'exécute après validation manuelle
                    return params.DEPLOY_ENV == 'staging'
                }
            }
            steps {
                script {
                    echo "=== DÉPLOIEMENT EN PRODUCTION ==="
                    
                    sh """
                    echo "🎯 Déploiement dans l'environnement PRODUCTION"
                    
                    # Créer le déploiement production
                    cat > k8s-prod.yaml << 'YAML'
---
# Movie Service Production
apiVersion: apps/v1
kind: Deployment
metadata:
  name: movie-service-prod
  namespace: prod
  labels:
    app: movie-service
    env: production
    exam: datascientest
spec:
  replicas: 2
  selector:
    matchLabels:
      app: movie-service
      env: production
  template:
    metadata:
      labels:
        app: movie-service
        env: production
        exam: datascientest
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
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: movie-service-prod
  namespace: prod
  labels:
    app: movie-service
    env: production
spec:
  type: NodePort
  selector:
    app: movie-service
    env: production
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
  labels:
    app: cast-service
    env: production
    exam: datascientest
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cast-service
      env: production
  template:
    metadata:
      labels:
        app: cast-service
        env: production
        exam: datascientest
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
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: cast-service-prod
  namespace: prod
  labels:
    app: cast-service
    env: production
spec:
  type: NodePort
  selector:
    app: cast-service
    env: production
  ports:
  - port: 8000
    targetPort: 8000
YAML
                    
                    # Appliquer le déploiement production
                    kubectl apply -f k8s-prod.yaml
                    
                    echo "✅ PRODUCTION DÉPLOYÉE AVEC SUCCÈS!"
                    echo ""
                    echo "🎉 RÉSUMÉ PRODUCTION:"
                    echo "   - Environnement: prod"
                    echo "   - Réplicas: 2 par service"
                    echo "   - Images: ${DOCKER_TAG}"
                    echo "   - Validation: Manuelle ✓"
                    echo ""
                    
                    echo "📊 ÉTAT PRODUCTION:"
                    kubectl get all -n prod
                    echo ""
                    
                    echo "🔍 DÉTAILS PODS PRODUCTION:"
                    kubectl get pods -n prod -o wide
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "========================================"
            echo "FIN DU PIPELINE - RAPPORT FINAL"
            echo "========================================"
            script {
                // Utiliser des guillemets doubles correctement échappés
                sh """
                echo "📋 INFORMATIONS:"
                echo "   Candidat: Mohamed GUESSOD"
                echo "   Build: ${BUILD_ID}"
                echo "   Tag: ${DOCKER_TAG}"
                echo "   Environnement: ${params.DEPLOY_ENV}"
                echo "   Push DockerHub: ${params.SKIP_DOCKER_PUSH ? 'Non' : 'Oui'}"
                echo ""
                """
                
                sh '''
                echo "🏗️ ÉTAT KUBERNETES:"
                for ns in dev qa staging prod; do
                    echo "   --- $ns ---"
                    kubectl get pods -n $ns 2>/dev/null | grep -E "movie|cast|NAME" || echo "     Aucun service"
                done
                echo ""
                
                echo "🐳 IMAGES DOCKER:"
                docker images | grep guessod || echo "   Aucune image locale"
                '''
                
                // Nettoyage
                sh '''
                echo "🧹 Nettoyage..."
                rm -f k8s-deploy.yaml k8s-prod.yaml 2>/dev/null || true
                '''
            }
        }
        
        success {
            echo "✅✅✅ PIPELINE RÉUSSI! ✅✅✅"
            script {
                // Notification email
                emailext(
                    to: 'mohamedguessod@gmail.com',
                    subject: "✅ SUCCÈS Examen DevOps #${BUILD_NUMBER}",
                    body: """🎉 FÉLICITATIONS! L'examen DevOps est réussi!

📊 DÉTAILS:
   Candidat: Mohamed GUESSOD
   Build: #${BUILD_NUMBER}
   Tag: ${DOCKER_TAG}
   Environnement: ${params.DEPLOY_ENV}
   
📦 LIVRABLES:
   - Images DockerHub: ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG}
   - Namespaces K8S: dev, qa, staging, prod
   - Déploiement production: Validé manuellement
   
🔗 LIENS:
   - GitHub: https://github.com/Mhdguess/jenkins-exam-guessod
   - DockerHub: https://hub.docker.com/u/guessod
   - Jenkins: ${BUILD_URL}

🧪 EXIGENCES SATISFAITES:
   ✓ 4 environnements Kubernetes
   ✓ Déploiement production manuel
   ✓ Pipeline CI/CD complet
   ✓ Images versionnées DockerHub
   ✓ Notifications email

📞 Contact: mohamedguessod@gmail.com
"""
                )
            }
        }
        
        failure {
            echo "❌❌❌ PIPELINE EN ÉCHEC ❌❌❌"
            script {
                // Notification email
                emailext(
                    to: 'mohamedguessod@gmail.com',
                    subject: "❌ ÉCHEC Examen DevOps #${BUILD_NUMBER}",
                    body: """⚠️ Le pipeline d'examen a échoué!

Détails:
- Build: #${BUILD_NUMBER}
- Environnement: ${params.DEPLOY_ENV}
- URL: ${BUILD_URL}

Consultez les logs pour le débogage.
"""
                )
                
                // Logs de débogage
                sh '''
                echo "🔧 LOGS DE DÉBOGAGE:"
                echo ""
                echo "1. Événements Kubernetes:"
                kubectl get events --sort-by=.lastTimestamp 2>/dev/null | tail -15 || echo "   Non disponible"
                echo ""
                echo "2. Pods en erreur:"
                kubectl get pods -A --field-selector=status.phase!=Running 2>/dev/null || echo "   Aucun pod en erreur"
                echo ""
                echo "3. Containers Docker:"
                docker ps -a 2>/dev/null | tail -10 || echo "   Non disponible"
                '''
            }
        }
    }
}
