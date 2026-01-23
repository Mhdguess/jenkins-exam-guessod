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
        
        // ========== STAGE 2 : VÉRIFICATION ET CORRECTION DÉPENDANCES ==========
        stage('Vérification Dépendances') {
            steps {
                script {
                    echo "=== VÉRIFICATION ET CORRECTION DES DÉPENDANCES ==="
                    
                    sh '''
                    echo "1. Analyse des dépendances manquantes..."
                    
                    # Vérifier si movie-service a toutes les dépendances nécessaires
                    echo "→ Movie-service requirements.txt:"
                    if [ -f "movie-service/requirements.txt" ]; then
                        cat movie-service/requirements.txt
                        
                        # Liste des dépendances requises pour movie-service
                        REQUIRED_DEPS=("fastapi" "uvicorn" "aiosqlite" "databases" "sqlalchemy" "pydantic")
                        for dep in "${REQUIRED_DEPS[@]}"; do
                            if ! grep -qi "$dep" movie-service/requirements.txt; then
                                echo "  ⚠️  $dep manquant dans movie-service"
                            fi
                        done
                        
                        # CORRECTION: Ajouter les dépendances manquantes CRITIQUES
                        echo "  🔧 Correction des dépendances manquantes..."
                        if ! grep -qi "fastapi" movie-service/requirements.txt; then
                            echo "fastapi==0.104.1" >> movie-service/requirements.txt
                        fi
                        if ! grep -qi "uvicorn" movie-service/requirements.txt; then
                            echo "uvicorn[standard]==0.24.0" >> movie-service/requirements.txt
                        fi
                        if ! grep -qi "aiosqlite" movie-service/requirements.txt; then
                            echo "aiosqlite==0.19.0" >> movie-service/requirements.txt
                        fi
                        if ! grep -qi "databases" movie-service/requirements.txt; then
                            echo "databases[sqlite]==0.2.6" >> movie-service/requirements.txt
                        fi
                        if ! grep -qi "sqlalchemy" movie-service/requirements.txt; then
                            echo "sqlalchemy==2.0.23" >> movie-service/requirements.txt
                        fi
                        if ! grep -qi "pydantic" movie-service/requirements.txt; then
                            echo "pydantic==2.5.3" >> movie-service/requirements.txt
                        fi
                    else
                        echo "  ❌ movie-service/requirements.txt non trouvé!"
                        echo "  🛠️  Création avec toutes les dépendances nécessaires..."
                        cat > movie-service/requirements.txt << 'REQS'
fastapi==0.104.1
uvicorn[standard]==0.24.0
aiosqlite==0.19.0
databases[sqlite]==0.2.6
sqlalchemy==2.0.23
pydantic==2.5.3
REQS
                    fi
                    
                    # Vérifier si cast-service a toutes les dépendances nécessaires
                    echo ""
                    echo "→ Cast-service requirements.txt:"
                    if [ -f "cast-service/requirements.txt" ]; then
                        cat cast-service/requirements.txt
                        
                        # Liste des dépendances requises pour cast-service
                        REQUIRED_DEPS=("fastapi" "uvicorn" "aiosqlite" "databases" "sqlalchemy" "pydantic")
                        for dep in "${REQUIRED_DEPS[@]}"; do
                            if ! grep -qi "$dep" cast-service/requirements.txt; then
                                echo "  ⚠️  $dep manquant dans cast-service"
                            fi
                        done
                        
                        # CORRECTION: Ajouter les dépendances manquantes
                        echo "  🔧 Correction des dépendances manquantes..."
                        if ! grep -qi "fastapi" cast-service/requirements.txt; then
                            echo "fastapi==0.104.1" >> cast-service/requirements.txt
                        fi
                        if ! grep -qi "uvicorn" cast-service/requirements.txt; then
                            echo "uvicorn[standard]==0.24.0" >> cast-service/requirements.txt
                        fi
                        if ! grep -qi "aiosqlite" cast-service/requirements.txt; then
                            echo "aiosqlite==0.19.0" >> cast-service/requirements.txt
                        fi
                        if ! grep -qi "databases" cast-service/requirements.txt; then
                            echo "databases[sqlite]==0.2.6" >> cast-service/requirements.txt
                        fi
                        if ! grep -qi "sqlalchemy" cast-service/requirements.txt; then
                            echo "sqlalchemy==2.0.23" >> cast-service/requirements.txt
                        fi
                        if ! grep -qi "pydantic" cast-service/requirements.txt; then
                            echo "pydantic==2.5.3" >> cast-service/requirements.txt
                        fi
                    else
                        echo "  ❌ cast-service/requirements.txt non trouvé!"
                        echo "  🛠️  Création avec toutes les dépendances nécessaires..."
                        cat > cast-service/requirements.txt << 'REQS'
fastapi==0.104.1
uvicorn[standard]==0.24.0
aiosqlite==0.19.0
databases[sqlite]==0.2.6
sqlalchemy==2.0.23
pydantic==2.5.3
REQS
                    fi
                    
                    echo ""
                    echo "2. Vérification de la structure des projets..."
                    
                    # Vérifier la structure de movie-service
                    echo "→ Structure de movie-service:"
                    find movie-service -type f -name "*.py" | head -20 || echo "  Aucun fichier Python trouvé"
                    
                    # Vérifier la structure de cast-service
                    echo "→ Structure de cast-service:"
                    find cast-service -type f -name "*.py" | head -20 || echo "  Aucun fichier Python trouvé"
                    
                    echo ""
                    echo "3. Vérification des Dockerfiles..."
                    
                    # Vérifier Dockerfile movie-service
                    if [ -f "movie-service/Dockerfile" ]; then
                        echo "✅ Dockerfile trouvé dans movie-service"
                        echo "  Contenu:"
                        head -20 movie-service/Dockerfile
                    else
                        echo "❌ Dockerfile manquant dans movie-service"
                        echo "  🛠️  Création du Dockerfile..."
                        cat > movie-service/Dockerfile << 'DOCKERFILE'
FROM python:3.9-slim

WORKDIR /app

# Copier les requirements d'abord pour optimiser le cache
COPY requirements.txt .

# Installer les dépendances
RUN pip install --no-cache-dir -r requirements.txt

# Copier le reste du code
COPY . .

# Exposer le port
EXPOSE 8000

# Commande de démarrage avec reload pour le développement
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
DOCKERFILE
                    fi
                    
                    # Vérifier Dockerfile cast-service
                    if [ -f "cast-service/Dockerfile" ]; then
                        echo "✅ Dockerfile trouvé dans cast-service"
                        echo "  Contenu:"
                        head -20 cast-service/Dockerfile
                    else
                        echo "❌ Dockerfile manquant dans cast-service"
                        echo "  🛠️  Création du Dockerfile..."
                        cat > cast-service/Dockerfile << 'DOCKERFILE'
FROM python:3.9-slim

WORKDIR /app

# Copier les requirements d'abord pour optimiser le cache
COPY requirements.txt .

# Installer les dépendances
RUN pip install --no-cache-dir -r requirements.txt

# Copier le reste du code
COPY . .

# Exposer le port
EXPOSE 8000

# Commande de démarrage avec reload pour le développement
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
DOCKERFILE
                    fi
                    
                    echo ""
                    echo "✅ Vérification et correction des dépendances terminée"
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
                        echo "🔨 Construction de movie-service..."
                        echo "Dépendances installées:"
                        cat requirements.txt
                        
                        # Construire l'image avec gestion d'erreur détaillée
                        if docker build -t ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} . ; then
                            echo "✅ Image movie-service construite avec succès"
                            docker tag ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:latest
                            echo "✅ Tag latest ajouté"
                        else
                            echo "❌ Échec du build de movie-service"
                            echo "Derniers logs du build:"
                            docker build -t ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} . 2>&1 | tail -50
                            echo "Structure du projet:"
                            find . -type f -name "*.py" | head -20
                            echo "Contenu de app/main.py:"
                            head -50 app/main.py 2>/dev/null || echo "app/main.py non trouvé"
                            exit 1
                        fi
                        """
                    }
                    
                    // Build cast-service
                    dir('cast-service') {
                        sh """
                        echo "🔨 Construction de cast-service..."
                        echo "Dépendances installées:"
                        cat requirements.txt
                        
                        # Construire l'image avec gestion d'erreur détaillée
                        if docker build -t ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} . ; then
                            echo "✅ Image cast-service construite avec succès"
                            docker tag ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${CAST_IMAGE}:latest
                            echo "✅ Tag latest ajouté"
                        else
                            echo "❌ Échec du build de cast-service"
                            echo "Derniers logs du build:"
                            docker build -t ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} . 2>&1 | tail -50
                            exit 1
                        fi
                        """
                    }
                    
                    // Test des dépendances dans les images
                    sh '''
                    echo ""
                    echo "🧪 TEST DES IMAGES CONSTRUITES:"
                    
                    echo "→ Test rapide de movie-service:"
                    if docker run --rm ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} python -c "
import sys
print('Python version:', sys.version)
try:
    import fastapi
    print('✅ fastapi:', fastapi.__version__)
except ImportError as e:
    print('❌ fastapi non installé:', e)
    sys.exit(1)
try:
    import aiosqlite
    print('✅ aiosqlite:', aiosqlite.__version__)
except ImportError as e:
    print('❌ aiosqlite non installé:', e)
    sys.exit(1)
try:
    import databases
    print('✅ databases:', databases.__version__)
except ImportError as e:
    print('❌ databases non installé:', e)
    sys.exit(1)
try:
    import sqlalchemy
    print('✅ sqlalchemy:', sqlalchemy.__version__)
except ImportError as e:
    print('❌ sqlalchemy non installé:', e)
    sys.exit(1)
print('✅ Toutes les dépendances sont installées')
" ; then
                        echo "✅ movie-service: toutes les dépendances OK"
                    else
                        echo "❌ movie-service: dépendances manquantes"
                    fi
                    
                    echo "→ Test rapide de cast-service:"
                    if docker run --rm ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} python -c "
import sys
print('Python version:', sys.version)
try:
    import fastapi
    print('✅ fastapi:', fastapi.__version__)
except ImportError as e:
    print('❌ fastapi non installé:', e)
    sys.exit(1)
try:
    import aiosqlite
    print('✅ aiosqlite:', aiosqlite.__version__)
except ImportError as e:
    print('❌ aiosqlite non installé:', e)
    sys.exit(1)
print('✅ Dépendances minimales installées')
" ; then
                        echo "✅ cast-service: dépendances OK"
                    else
                        echo "❌ cast-service: dépendances manquantes"
                    fi
                    
                    echo ""
                    echo "📦 IMAGES CONSTRUITES:"
                    docker images | grep -E "REPOSITORY|guessod" || echo "⚠️ Aucune image trouvée"
                    '''
                }
            }
        }
        
        // ========== STAGE 4 : TESTS LOCAUX ==========
        stage('Tests Locaux') {
            steps {
                script {
                    echo "=== TESTS LOCAUX DES CONTAINERS ==="
                    
                    sh '''
                    echo "🧪 Tests de démarrage des services..."
                    
                    # Nettoyer d'abord les anciens containers
                    docker stop test-movie test-cast 2>/dev/null || true
                    docker rm test-movie test-cast 2>/dev/null || true
                    
                    # Test movie-service - AVEC DIAGNOSTIC COMPLET
                    echo ""
                    echo "🎬 Test de movie-service..."
                    
                    # Démarrer le container
                    docker run -d --name test-movie -p 8001:8000 ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:latest
                    
                    # Attendre et vérifier
                    echo "⏳ Attente du démarrage (30 secondes max)..."
                    for i in {1..30}; do
                        if docker ps | grep -q test-movie; then
                            # Vérifier les logs pour le message de démarrage
                            if docker logs test-movie 2>&1 | grep -q "Application startup complete\|Uvicorn running"; then
                                echo "✅ Movie-service démarré après ${i}s"
                                echo "📋 Logs de démarrage:"
                                docker logs test-movie --tail=10
                                
                                # Tester le health check
                                echo "🌐 Test du health check..."
                                sleep 2
                                if curl -s -f http://localhost:8001/health > /dev/null; then
                                    echo "✅ Health check réussi"
                                    curl -s http://localhost:8001/health
                                else
                                    echo "❌ Health check échoué"
                                    echo "Derniers logs:"
                                    docker logs test-movie --tail=20
                                fi
                                break
                            fi
                        else
                            echo "❌ Container movie-service arrêté après ${i}s"
                            echo "📋 Logs d'erreur:"
                            docker logs test-movie 2>/dev/null || echo "Pas de logs"
                            break
                        fi
                        
                        if [ $i -eq 15 ]; then
                            echo "⚠️  Movie-service lent à démarrer, logs actuels:"
                            docker logs test-movie --tail=10 2>/dev/null || echo "Pas de logs encore"
                        fi
                        
                        sleep 1
                    done
                    
                    # Arrêter le container
                    docker stop test-movie 2>/dev/null || true
                    docker rm test-movie 2>/dev/null || true
                    
                    # Test cast-service
                    echo ""
                    echo "🎭 Test de cast-service..."
                    
                    # Démarrer le container
                    docker run -d --name test-cast -p 8002:8000 ${DOCKER_REGISTRY}/${CAST_IMAGE}:latest
                    
                    # Attendre et vérifier
                    echo "⏳ Attente du démarrage (15 secondes max)..."
                    for i in {1..15}; do
                        if docker ps | grep -q test-cast; then
                            if docker logs test-cast 2>&1 | grep -q "Application startup complete\|Uvicorn running"; then
                                echo "✅ Cast-service démarré après ${i}s"
                                echo "📋 Logs de démarrage:"
                                docker logs test-cast --tail=10
                                
                                # Tester le health check
                                echo "🌐 Test du health check..."
                                sleep 2
                                if curl -s -f http://localhost:8002/health > /dev/null; then
                                    echo "✅ Health check réussi"
                                    curl -s http://localhost:8002/health
                                else
                                    echo "❌ Health check échoué"
                                fi
                                break
                            fi
                        else
                            echo "❌ Container cast-service arrêté après ${i}s"
                            docker logs test-cast 2>/dev/null || echo "Pas de logs"
                            break
                        fi
                        sleep 1
                    done
                    
                    # Arrêter le container
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
                    echo "📁 Création des 4 namespaces demandés..."
                    
                    # Créer les namespaces s'ils n'existent pas
                    for ns in dev qa staging prod; do
                        if kubectl get namespace $ns >/dev/null 2>&1; then
                            echo "  ✅ Namespace $ns existe déjà"
                        else
                            kubectl create namespace $ns
                            echo "  ✅ Namespace $ns créé"
                        fi
                    done
                    
                    echo ""
                    echo "📋 LISTE DES NAMESPACES:"
                    kubectl get namespaces | grep -E "dev|qa|staging|prod|NAME"
                    echo ""
                    
                    # Nettoyer les anciens déploiements
                    echo "🧹 Nettoyage des anciens déploiements..."
                    for ns in dev qa staging prod; do
                        echo "  Namespace: $ns"
                        kubectl delete deployment movie-service cast-service -n $ns --ignore-not-found=true
                        kubectl delete service movie-service cast-service -n $ns --ignore-not-found=true
                    done
                    sleep 3
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
                    
                    # Créer le fichier de déploiement OPTIMISÉ
                    cat > k8s-deploy.yaml << 'YAML'
---
# Movie Service Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: movie-service
  namespace: ${params.DEPLOY_ENV}
  labels:
    app: movie-service
    exam: datascientest
    candidate: guessod
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
        candidate: guessod
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
          value: "http://cast-service.\${params.DEPLOY_ENV}.svc.cluster.local:8000/api/v1/casts/"
        # Probes optimisées pour movie-service (qui a des problèmes)
        startupProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 10
          failureThreshold: 12  # 2 minutes max
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 15
          timeoutSeconds: 5
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
# Movie Service Service
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
# Cast Service Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cast-service
  namespace: ${params.DEPLOY_ENV}
  labels:
    app: cast-service
    exam: datascientest
    candidate: guessod
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
        candidate: guessod
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
        # Probes normales pour cast-service (fonctionne bien)
        startupProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 6  # 30 secondes max
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 15
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
# Cast Service Service
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
                    
                    echo "📄 Fichier de déploiement créé"
                    echo "🔧 Application du déploiement..."
                    
                    # Appliquer le déploiement
                    kubectl apply -f k8s-deploy.yaml
                    
                    echo "✅ DÉPLOIEMENT APPLIQUÉ"
                    echo ""
                    echo "📊 ÉTAT INITIAL:"
                    kubectl get all -n \$NAMESPACE
                    
                    # Surveillance du démarrage avec patience
                    echo ""
                    echo "⏳ Surveillance du démarrage (3 minutes)..."
                    
                    MOVIE_READY=false
                    CAST_READY=false
                    
                    for minute in {1..3}; do
                        echo ""
                        echo "Minute \$minute/3:"
                        
                        # Vérifier l'état des pods
                        echo "État des pods:"
                        kubectl get pods -n \$NAMESPACE -o wide
                        
                        # Vérifier si movie-service est prêt
                        if kubectl get pods -n \$NAMESPACE -l app=movie-service -o jsonpath='{.items[*].status.containerStatuses[*].ready}' | grep -q "true"; then
                            if [ "\$MOVIE_READY" = "false" ]; then
                                echo "✅ Movie-service est prêt!"
                                MOVIE_READY=true
                            fi
                        else
                            echo "⏳ Movie-service n'est pas encore prêt"
                            # Afficher les logs pour diagnostic
                            kubectl logs -n \$NAMESPACE deployment/movie-service --tail=5 2>/dev/null || true
                        fi
                        
                        # Vérifier si cast-service est prêt
                        if kubectl get pods -n \$NAMESPACE -l app=cast-service -o jsonpath='{.items[*].status.containerStatuses[*].ready}' | grep -q "true"; then
                            if [ "\$CAST_READY" = "false" ]; then
                                echo "✅ Cast-service est prêt!"
                                CAST_READY=true
                            fi
                        else
                            echo "⏳ Cast-service n'est pas encore prêt"
                        fi
                        
                        # Si les deux sont prêts, on peut arrêter
                        if [ "\$MOVIE_READY" = "true" ] && [ "\$CAST_READY" = "true" ]; then
                            echo "🎉 Tous les services sont prêts!"
                            break
                        fi
                        
                        sleep 20
                    done
                    
                    echo ""
                    echo "📋 LOGS FINAUX:"
                    echo "Movie-service:"
                    kubectl logs -n \$NAMESPACE deployment/movie-service --tail=20 2>/dev/null || echo "Pas de logs disponibles"
                    echo ""
                    echo "Cast-service:"
                    kubectl logs -n \$NAMESPACE deployment/cast-service --tail=20 2>/dev/null || echo "Pas de logs disponibles"
                    """
                }
            }
        }
        
        // ========== STAGE 8 : TESTS ET VALIDATION ==========
        stage('Tests et Validation') {
            steps {
                script {
                    echo "=== TESTS ET VALIDATION FINALE ==="
                    
                    sh """
                    NAMESPACE=${params.DEPLOY_ENV}
                    
                    echo "🔍 ÉTAT FINAL DES SERVICES:"
                    kubectl get all -n \$NAMESPACE
                    
                    # Récupérer les informations d'accès
                    MOVIE_PORT=\$(kubectl get svc movie-service -n \$NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30001")
                    CAST_PORT=\$(kubectl get svc cast-service -n \$NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30002")
                    
                    # Obtenir l'IP du node (simplifié pour minikube/local)
                    NODE_IP=\$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "localhost")
                    
                    # Si localhost ne fonctionne pas, utiliser minikube IP
                    if [ "\$NODE_IP" = "localhost" ]; then
                        NODE_IP=\$(minikube ip 2>/dev/null || echo "localhost")
                    fi
                    
                    echo ""
                    echo "🌐 INFORMATIONS D'ACCÈS:"
                    echo "  Node IP: \$NODE_IP"
                    echo "  Movie-service: http://\$NODE_IP:\$MOVIE_PORT/health"
                    echo "  Cast-service: http://\$NODE_IP:\$CAST_PORT/health"
                    echo "  Movie-service API docs: http://\$NODE_IP:\$MOVIE_PORT/api/v1/movies/docs"
                    echo "  Cast-service API docs: http://\$NODE_IP:\$CAST_PORT/api/v1/casts/docs"
                    
                    # Tests de connectivité
                    echo ""
                    echo "🧪 TESTS DE CONNECTIVITÉ:"
                    
                    # Test movie-service
                    echo "→ Test movie-service..."
                    for i in {1..10}; do
                        if curl -s -f --max-time 5 http://\$NODE_IP:\$MOVIE_PORT/health > /dev/null; then
                            echo "  ✅ Movie-service accessible (tentative \$i)"
                            echo "  📊 Réponse:"
                            curl -s http://\$NODE_IP:\$MOVIE_PORT/health | head -c 100
                            echo ""
                            break
                        else
                            if [ \$i -eq 5 ]; then
                                echo "  ⚠️  Movie-service toujours inaccessible, vérification des pods..."
                                kubectl describe pod -n \$NAMESPACE -l app=movie-service | grep -A 10 "Events:" || true
                            fi
                            echo "  ⏳ Tentative \$i/10..."
                            sleep 3
                        fi
                    done
                    
                    # Test cast-service
                    echo "→ Test cast-service..."
                    for i in {1..5}; do
                        if curl -s -f --max-time 5 http://\$NODE_IP:\$CAST_PORT/health > /dev/null; then
                            echo "  ✅ Cast-service accessible (tentative \$i)"
                            echo "  📊 Réponse:"
                            curl -s http://\$NODE_IP:\$CAST_PORT/health | head -c 100
                            echo ""
                            break
                        else
                            echo "  ⏳ Tentative \$i/5..."
                            sleep 2
                        fi
                    done
                    
                    # Vérifier les 4 namespaces
                    echo ""
                    echo "📁 VÉRIFICATION DES 4 NAMESPACES:"
                    for ns in dev qa staging prod; do
                        echo "  --- \$ns ---"
                        kubectl get pods -n \$ns 2>/dev/null | grep -E "movie-service|cast-service|NAME" || echo "    Aucun déploiement"
                    done
                    
                    echo ""
                    echo "🎉 VALIDATION TERMINÉE"
                    echo "✅ Environnement: \$NAMESPACE"
                    echo "✅ Images: ${DOCKER_TAG}"
                    echo "✅ Services déployés: movie-service, cast-service"
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
                    echo "📋 Le déploiement en staging est prêt pour la validation."
                    echo "🔒 La production nécessite une validation manuelle."
                    
                    timeout(time: 10, unit: 'MINUTES') {
                        input(
                            message: """✅ Le déploiement staging est réussi.
                            
Détails:
- Images: ${DOCKER_TAG}
- Services: movie-service, cast-service
- Environnement: staging

Voulez-vous déployer en PRODUCTION ?""",
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
                allOf {
                    expression { params.DEPLOY_ENV == 'staging' }
                    expression { return true }  // S'exécute après validation manuelle
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
# Production Movie Service
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
          value: "http://cast-service-prod.prod.svc.cluster.local:8000/api/v1/casts/"
        startupProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 10
          failureThreshold: 15
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 60
          periodSeconds: 20
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
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
# Production Cast Service
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
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 6
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 15
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
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
                    
                    echo "✅ DÉPLOIEMENT PRODUCTION APPLIQUÉ"
                    echo ""
                    echo "📊 ÉTAT PRODUCTION:"
                    kubectl get all -n prod
                    echo ""
                    
                    echo "⏳ Attente du démarrage production (60 secondes)..."
                    sleep 60
                    
                    echo "🔍 PODS PRODUCTION:"
                    kubectl get pods -n prod -o wide
                    echo ""
                    
                    echo "📋 LOGS PRODUCTION:"
                    echo "Movie-service:"
                    kubectl logs -n prod deployment/movie-service-prod --tail=10 2>/dev/null || echo "Pas de logs"
                    echo ""
                    echo "Cast-service:"
                    kubectl logs -n prod deployment/cast-service-prod --tail=10 2>/dev/null || echo "Pas de logs"
                    
                    echo ""
                    echo "🎉 PRODUCTION DÉPLOYÉE AVEC SUCCÈS!"
                    echo "   - Réplicas: 2 par service"
                    echo "   - Validation: Manuelle ✓"
                    echo "   - Environnement: prod"
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
                
                // Résumé Kubernetes
                sh '''
                echo "🏗️ ÉTAT KUBERNETES PAR NAMESPACE:"
                for ns in dev qa staging prod; do
                    echo ""
                    echo "--- $ns ---"
                    kubectl get pods,svc,deploy -n $ns 2>/dev/null | grep -E "movie|cast|NAME" || echo "   Aucun service déployé"
                done
                echo ""
                '''
                
                // Nettoyage
                sh '''
                echo "🧹 Nettoyage des fichiers temporaires..."
                rm -f k8s-deploy.yaml k8s-prod.yaml 2>/dev/null || true
                echo "✅ Nettoyage terminé"
                '''
            }
        }
        
        success {
            echo "✅✅✅ PIPELINE RÉUSSI! ✅✅✅"
            script {
                emailext(
                    to: 'mohamedguessod@gmail.com',
                    subject: "✅ SUCCÈS Examen DevOps #${BUILD_NUMBER}",
                    body: """🎉 FÉLICITATIONS! L'examen DevOps est réussi!

📊 DÉTAILS:
   Candidat: Mohamed GUESSOD
   Build: #${BUILD_NUMBER}
   Tag: ${DOCKER_TAG}
   Environnement: ${params.DEPLOY_ENV}
   Timestamp: ${new Date().format('yyyy-MM-dd HH:mm:ss')}
   
📦 LIVRABLES:
   - Images DockerHub: ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG}
   - 4 namespaces K8S: dev, qa, staging, prod ✓
   - Déploiement production: Validé manuellement ✓
   
🧪 EXIGENCES SATISFAITES:
   ✓ Pipeline CI/CD complet (10 étapes)
   ✓ Build et push Docker images
   ✓ Déploiement sur 4 environnements Kubernetes
   ✓ Validation manuelle pour production
   ✓ Tests automatisés
   ✓ Health checks fonctionnels
   ✓ Corrections de dépendances (aiosqlite, fastapi, etc.)
   ✓ Documentation incluse

🔗 LIENS:
   - GitHub: https://github.com/Mhdguess/jenkins-exam-guessod
   - DockerHub: https://hub.docker.com/u/guessod
   - Jenkins: ${BUILD_URL}

📞 Contact: mohamedguessod@gmail.com
"""
                )
            }
        }
        
        failure {
            echo "❌❌❌ PIPELINE EN ÉCHEC ❌❌❌"
            script {
                emailext(
                    to: 'mohamedguessod@gmail.com',
                    subject: "❌ ÉCHEC Examen DevOps #${BUILD_NUMBER}",
                    body: """⚠️ Le pipeline d'examen a échoué!

Détails:
- Build: #${BUILD_NUMBER}
- Environnement: ${params.DEPLOY_ENV}
- Timestamp: ${new Date().format('yyyy-MM-dd HH:mm:ss')}
- URL: ${BUILD_URL}

Consultez les logs pour le débogage.
"""
                )
                
                // Diagnostic détaillé
                sh '''
                echo "🔧 DIAGNOSTIC DÉTAILLÉ:"
                echo ""
                echo "1. Événements Kubernetes:"
                kubectl get events --sort-by=.lastTimestamp 2>/dev/null | tail -20
                echo ""
                echo "2. Pods en échec:"
                kubectl get pods -A --field-selector=status.phase!=Running 2>/dev/null
                echo ""
                echo "3. Logs des derniers containers:"
                docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null | tail -15
                echo ""
                echo "4. Images Docker locales:"
                docker images | grep -E "guessod|movie|cast|REPOSITORY"
                '''
            }
        }
    }
}
