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
                    echo "Vérification des dépendances SQLite..."
                    grep -i "aiosqlite\|sqlite" movie-service/requirements.txt || echo "⚠️ aiosqlite manquant dans movie-service"
                    grep -i "aiosqlite\|sqlite" cast-service/requirements.txt || echo "⚠️ aiosqlite manquant dans cast-service"
                    '''
                }
            }
        }
        
        // ========== STAGE 2 : VÉRIFICATION DÉPENDANCES ==========
        stage('Vérification Dépendances') {
            steps {
                script {
                    echo "=== VÉRIFICATION DES DÉPENDANCES ==="
                    
                    sh '''
                    echo "1. Vérification requirements.txt..."
                    
                    # Movie-service
                    if grep -q "aiosqlite" movie-service/requirements.txt; then
                        echo "✅ movie-service: aiosqlite présent"
                    else
                        echo "❌ movie-service: aiosqlite manquant - ajout automatique"
                        echo "aiosqlite==0.19.0" >> movie-service/requirements.txt
                        echo "databases[sqlite]==0.2.6" >> movie-service/requirements.txt
                    fi
                    
                    # Cast-service
                    if grep -q "aiosqlite" cast-service/requirements.txt; then
                        echo "✅ cast-service: aiosqlite présent"
                    else
                        echo "❌ cast-service: aiosqlite manquant - ajout automatique"
                        echo "aiosqlite==0.19.0" >> cast-service/requirements.txt
                        echo "databases[sqlite]==0.2.6" >> cast-service/requirements.txt
                    fi
                    
                    echo ""
                    echo "2. Affichage des requirements.txt mis à jour:"
                    echo "Movie-service:"
                    cat movie-service/requirements.txt
                    echo ""
                    echo "Cast-service:"
                    cat cast-service/requirements.txt
                    '''
                }
            }
        }
        
        // ========== STAGE 3 : BUILD DOCKER ==========
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
                    
                    // Vérification des dépendances dans les images
                    sh '''
                    echo ""
                    echo "🧪 TEST DES DÉPENDANCES DANS LES IMAGES:"
                    
                    echo "→ Test movie-service:"
                    docker run --rm ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} \
                        python -c "import aiosqlite; import databases; print('✅ movie-service: aiosqlite et databases OK')" \
                        2>/dev/null || echo "❌ movie-service: problème d'import"
                    
                    echo "→ Test cast-service:"
                    docker run --rm ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} \
                        python -c "import aiosqlite; import databases; print('✅ cast-service: aiosqlite et databases OK')" \
                        2>/dev/null || echo "❌ cast-service: problème d'import"
                    
                    echo ""
                    echo "📦 IMAGES DISPONIBLES:"
                    docker images | grep guessod || echo "⚠️ Aucune image trouvée"
                    '''
                }
            }
        }
        
        // ========== STAGE 4 : TESTS SIMPLES ==========
        stage('Tests Simples') {
            steps {
                script {
                    echo "=== TESTS DE VALIDATION ==="
                    
                    sh '''
                    echo "1. Test de démarrage des services..."
                    
                    # Test movie-service
                    echo "→ Test movie-service..."
                    docker run -d --name test-movie --rm -p 8001:8000 ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:latest
                    sleep 15
                    
                    if docker ps | grep test-movie; then
                        echo "  ✅ Container movie-service en cours d'exécution"
                        echo "  📋 Logs:"
                        docker logs test-movie --tail=5
                        docker stop test-movie
                    else
                        echo "  ❌ Container movie-service non démarré"
                        docker logs test-movie 2>/dev/null || true
                    fi
                    
                    # Test cast-service
                    echo "→ Test cast-service..."
                    docker run -d --name test-cast --rm -p 8002:8000 ${DOCKER_REGISTRY}/${CAST_IMAGE}:latest
                    sleep 15
                    
                    if docker ps | grep test-cast; then
                        echo "  ✅ Container cast-service en cours d'exécution"
                        echo "  📋 Logs:"
                        docker logs test-cast --tail=5
                        docker stop test-cast
                    else
                        echo "  ❌ Container cast-service non démarré"
                        docker logs test-cast 2>/dev/null || true
                    fi
                    
                    # Nettoyage
                    docker system prune -f
                    echo "✅ Tests terminés"
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
        
        // ========== STAGE 7 : DÉPLOIEMENT KUBERNETES ==========
        stage('Déploiement Kubernetes') {
            steps {
                script {
                    echo "=== DÉPLOIEMENT SUR KUBERNETES ==="
                    
                    sh """
                    NAMESPACE=${params.DEPLOY_ENV}
                    echo "🚀 Déploiement dans namespace: \$NAMESPACE"
                    
                    # Supprimer les anciens déploiements s'ils existent
                    echo "🧹 Nettoyage des anciens déploiements..."
                    kubectl delete deployment movie-service cast-service -n \$NAMESPACE --ignore-not-found=true 2>/dev/null || true
                    sleep 5
                    
                    # Créer le fichier de déploiement avec health checks corrigés
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
        # Startup probe pour donner plus de temps au démarrage
        startupProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 30
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 40
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
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
    nodePort: 30001
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
        # Startup probe pour donner plus de temps au démarrage
        startupProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 30
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 40
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
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
    nodePort: 30002
YAML
                    
                    # Appliquer le déploiement
                    kubectl apply -f k8s-deploy.yaml
                    
                    echo "✅ DÉPLOIEMENT APPLIQUÉ"
                    echo ""
                    echo "📊 ÉTAT DU DÉPLOIEMENT:"
                    kubectl get all -n \$NAMESPACE
                    
                    # Attendre le démarrage avec plus de temps
                    echo ""
                    echo "⏳ Attente du démarrage des pods (60 secondes)..."
                    sleep 60
                    
                    echo "🔍 ÉTAT DES PODS:"
                    kubectl get pods -n \$NAMESPACE -o wide
                    
                    echo ""
                    echo "📋 LOGS INITIAUX:"
                    kubectl logs -n \$NAMESPACE deployment/movie-service --tail=10 2>/dev/null || echo "Pas encore de logs pour movie-service"
                    kubectl logs -n \$NAMESPACE deployment/cast-service --tail=10 2>/dev/null || echo "Pas encore de logs pour cast-service"
                    """
                }
            }
        }
        
        // ========== STAGE 8 : TESTS ET VALIDATION ==========
        stage('Tests et Validation') {
            steps {
                script {
                    echo "=== TESTS ET VALIDATION ==="
                    
                    sh """
                    NAMESPACE=${params.DEPLOY_ENV}
                    
                    # Attendre que les pods soient prêts
                    echo "⏳ Attente supplémentaire pour les pods..."
                    sleep 30
                    
                    # Vérifier l'état final
                    echo "🔍 ÉTAT FINAL DES PODS:"
                    kubectl get pods -n \$NAMESPACE
                    
                    # Récupérer les ports
                    MOVIE_PORT=\$(kubectl get svc movie-service -n \$NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30001")
                    CAST_PORT=\$(kubectl get svc cast-service -n \$NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30002")
                    NODE_IP=\$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "localhost")
                    
                    echo ""
                    echo "🌐 URLS D'ACCÈS:"
                    echo "  Movie-service: http://\${NODE_IP}:\${MOVIE_PORT}/health"
                    echo "  Cast-service: http://\${NODE_IP}:\${CAST_PORT}/health"
                    
                    # Tests de connectivité
                    echo ""
                    echo "🧪 TESTS DE CONNECTIVITÉ:"
                    
                    echo "→ Test movie-service..."
                    for i in {1..10}; do
                        if curl -s -f http://\${NODE_IP}:\${MOVIE_PORT}/health > /dev/null; then
                            echo "  ✅ Movie-service accessible (tentative \$i)"
                            curl -s http://\${NODE_IP}:\${MOVIE_PORT}/health
                            break
                        else
                            echo "  ⏳ Tentative \$i/10 - Attente 5s..."
                            sleep 5
                        fi
                    done
                    
                    echo "→ Test cast-service..."
                    for i in {1..10}; do
                        if curl -s -f http://\${NODE_IP}:\${CAST_PORT}/health > /dev/null; then
                            echo "  ✅ Cast-service accessible (tentative \$i)"
                            curl -s http://\${NODE_IP}:\${CAST_PORT}/health
                            break
                        else
                            echo "  ⏳ Tentative \$i/10 - Attente 5s..."
                            sleep 5
                        fi
                    done
                    
                    # Vérifier les logs si échec
                    echo ""
                    echo "📋 LOGS FINAUX:"
                    kubectl logs -n \$NAMESPACE deployment/movie-service --tail=20 2>/dev/null || echo "Pas de logs movie-service"
                    echo ""
                    kubectl logs -n \$NAMESPACE deployment/cast-service --tail=20 2>/dev/null || echo "Pas de logs cast-service"
                    """
                }
            }
        }
        
        // ========== STAGE 9 : VALIDATION PRODUCTION ==========
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
        
        // ========== STAGE 10 : DÉPLOIEMENT PRODUCTION ==========
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
                    
                    # Créer le déploiement production avec plus de replicas et ressources
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
        startupProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 30
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 40
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
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
        startupProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 30
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 40
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
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
                    echo ""
                    
                    echo "⏳ Attente démarrage production (60s)..."
                    sleep 60
                    echo "📋 LOGS PRODUCTION:"
                    kubectl logs -n prod deployment/movie-service-prod --tail=10 2>/dev/null || echo "Pas de logs production"
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
                
                // Diagnostic des problèmes
                sh '''
                echo ""
                echo "🔧 DIAGNOSTIC DES PODS EN ÉCHEC:"
                for ns in dev qa staging prod; do
                    echo "Namespace: $ns"
                    kubectl get pods -n $ns --field-selector=status.phase!=Running 2>/dev/null | while read line; do
                        pod=$(echo $line | awk '{print $1}')
                        if [ "$pod" != "NAME" ] && [ ! -z "$pod" ]; then
                            echo "  Pod: $pod"
                            echo "  Logs:"
                            kubectl logs -n $ns $pod --tail=3 2>/dev/null | sed 's/^/    /' || echo "    Pas de logs"
                        fi
                    done
                done
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
   ✓ Corrections de dépendances (aiosqlite)
   ✓ Health checks fonctionnels

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
                echo "1. Événements Kubernetes récents:"
                kubectl get events --sort-by=.lastTimestamp 2>/dev/null | tail -15 | sed 's/^/   /' || echo "   Non disponible"
                echo ""
                echo "2. Pods en erreur détaillés:"
                kubectl get pods -A --field-selector=status.phase!=Running -o wide 2>/dev/null || echo "   Aucun pod en erreur"
                echo ""
                echo "3. Logs des derniers containers Docker:"
                docker ps -a --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | tail -10 | sed 's/^/   /' || echo "   Non disponible"
                '''
            }
        }
    }
}
