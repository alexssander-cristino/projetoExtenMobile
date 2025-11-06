from flask import Flask, request, jsonify
from flask_cors import CORS
from database import db
from models import Paciente, Protocolo, Prescricao, Acompanhamento, Alta
import pymysql
import socket
from datetime import datetime
import traceback
from sqlalchemy import text, inspect

# Instalar driver PyMySQL
pymysql.install_as_MySQLdb()

app = Flask(__name__)
CORS(app)

# Configuração MySQL (XAMPP)
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://root:@localhost:3306/hospital_db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
    'pool_timeout': 20,
    'pool_recycle': -1,
    'pool_pre_ping': True
}

db.init_app(app)

# 🎨 FUNÇÕES PARA LOGS COLORIDOS
def print_header():
    print("\n" + "="*60)
    print("🏥 INSULIN PRESCRIBER - API FLASK")
    print("="*60)

def print_success(message):
    print(f"✅ {datetime.now().strftime('%H:%M:%S')} | {message}")

def print_error(message):
    print(f"❌ {datetime.now().strftime('%H:%M:%S')} | {message}")

def print_info(message):
    print(f"ℹ️  {datetime.now().strftime('%H:%M:%S')} | {message}")

def print_warning(message):
    print(f"⚠️  {datetime.now().strftime('%H:%M:%S')} | {message}")

def print_database(message):
    print(f"🗄️  {datetime.now().strftime('%H:%M:%S')} | {message}")

def print_request(method, endpoint, data=None):
    print(f"🌐 {datetime.now().strftime('%H:%M:%S')} | {method} {endpoint}")
    if data and len(str(data)) < 200:
        print(f"   📦 Dados: {data}")

def print_separator():
    print("-" * 60)

# Inicialização do banco
print_header()
print_info("Iniciando configuração do banco de dados...")

with app.app_context():
    try:
        print_database("Testando conexão com MySQL...")
        
        with db.engine.connect() as connection:
            result = connection.execute(text('SELECT 1'))
            result.fetchone()
        
        print_success("Conexão com MySQL estabelecida!")
        
        print_database("Criando tabelas no banco 'hospital_db'...")
        db.create_all()
        print_success("Todas as tabelas criadas/verificadas com sucesso!")
        
        inspector = inspect(db.engine)
        tables = inspector.get_table_names()
        print_database(f"Tabelas disponíveis: {', '.join(tables)}")
        
        if tables:
            print_success(f"✨ {len(tables)} tabelas encontradas no banco!")
        else:
            print_warning("Nenhuma tabela encontrada - verificar models.py")
        
    except Exception as e:
        print_error(f"Erro na configuração do banco: {str(e)}")
        print_error("Possíveis causas:")
        print_error("1. XAMPP MySQL não está rodando")
        print_error("2. Banco 'hospital_db' não existe")
        print_error("3. Permissões de acesso")
        print_info("💡 Solução: Verifique XAMPP e crie o banco via phpMyAdmin")

print_separator()

# ===============================
# ROTAS PRINCIPAIS
# ===============================

@app.route('/health')
def health_check():
    print_request('GET', '/health')
    try:
        with db.engine.connect() as connection:
            connection.execute(text('SELECT 1'))
        
        print_success("Health check - Sistema OK")
        return jsonify({
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "database": "connected",
            "message": "Sistema funcionando normalmente"
        })
    except Exception as e:
        print_error(f"Health check falhou: {str(e)}")
        return jsonify({
            "status": "unhealthy", 
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }), 500

@app.route('/network-info')
def network_info():
    print_request('GET', '/network-info')
    try:
        hostname = socket.gethostname()
        local_ip = socket.gethostbyname(hostname)
        
        print_success(f"Info de rede obtida: {local_ip}")
        return jsonify({
            "hostname": hostname,
            "local_ip": local_ip,
            "port": 5000,
            "suggested_urls": [
                f"http://{local_ip}:5000",
                "http://10.0.2.2:5000",
                "http://127.0.0.1:5000"
            ]
        })
    except Exception as e:
        print_error(f"Erro ao obter info de rede: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/')
def home():
    print_request('GET', '/')
    response = {
        "mensagem": "🚀 API Flask conectada com sucesso!",
        "status": "online",
        "timestamp": datetime.now().isoformat(),
        "banco": "hospital_db",
        "version": "2.0",
        "rotas_disponiveis": [
            "/health - Status do sistema",
            "/network-info - Informações de rede",
            "/pacientes - Gerenciar pacientes",
            "/protocolos - Gerenciar protocolos",
            "/prescricoes - Gerenciar prescrições", 
            "/acompanhamentos - Registrar glicemias",
            "/altas - Processar altas"
        ]
    }
    print_success("✨ Rota principal acessada com sucesso")
    return jsonify(response)

# ===============================
# ROTAS DE PACIENTES
# ===============================

@app.route('/pacientes', methods=['GET'])
def listar_pacientes():
    print_request('GET', '/pacientes')
    try:
        pacientes = Paciente.query.all()
        print_database(f"Encontrados {len(pacientes)} pacientes no banco")
        
        result = [{
            'id': p.id,
            'nome': p.nome,
            'prontuario': p.prontuario,
            'sexo': p.sexo,
            'idade': p.idade,
            'peso': p.peso,
            'altura': p.altura,
            'imc': p.imc,
            'egfr': p.egfr,
            'cenario': p.cenario,
            'local_internacao': p.local_internacao,
            'data_cadastro': p.data_cadastro.isoformat() if p.data_cadastro else None
        } for p in pacientes]
        
        print_success(f"📋 Lista de pacientes retornada ({len(result)} registros)")
        return jsonify(result)
        
    except Exception as e:
        print_error(f"Erro ao listar pacientes: {str(e)}")
        return jsonify({'error': 'Erro interno do servidor'}), 500

@app.route('/pacientes', methods=['POST'])
def criar_paciente():
    data = request.json
    print_request('POST', '/pacientes', {'nome': data.get('nome'), 'cenario': data.get('cenario')})
    
    try:
        if not data.get('nome') or not data.get('nome').strip():
            print_warning("Tentativa de criar paciente sem nome")
            return jsonify({'error': 'Nome é obrigatório'}), 400
        
        novo = Paciente(
            nome=data['nome'].strip(),
            prontuario=data.get('prontuario'),
            sexo=data.get('sexo'),
            idade=data.get('idade'),
            peso=data.get('peso'),
            altura=data.get('altura'),
            creatinina=data.get('creatinina'),
            local_internacao=data.get('local_internacao'),
            imc=data.get('imc'),
            egfr=data.get('egfr'),
            cenario=data.get('cenario'),
            categoria=data.get('categoria')
        )
        
        db.session.add(novo)
        db.session.commit()
        
        print_success(f"✨ Paciente criado: ID={novo.id}, Nome={novo.nome}")
        print_database(f"📊 Dados: IMC={novo.imc}, TFG={novo.egfr}, Cenário={novo.cenario}")
        
        return jsonify({
            'message': 'Paciente cadastrado com sucesso', 
            'id': novo.id,
            'nome': novo.nome
        })
        
    except Exception as e:
        print_error(f"Erro ao criar paciente: {str(e)}")
        print_error(f"Dados recebidos: {data}")
        db.session.rollback()
        return jsonify({'error': 'Erro ao salvar paciente no banco'}), 500

@app.route('/pacientes/<int:paciente_id>', methods=['GET'])
def buscar_paciente(paciente_id):
    print_request('GET', f'/pacientes/{paciente_id}')
    
    try:
        paciente = Paciente.query.get_or_404(paciente_id)
        print_success(f"Paciente encontrado: {paciente.nome}")
        
        return jsonify({
            'id': paciente.id,
            'nome': paciente.nome,
            'prontuario': paciente.prontuario,
            'sexo': paciente.sexo,
            'idade': paciente.idade,
            'peso': paciente.peso,
            'altura': paciente.altura,
            'imc': paciente.imc,
            'egfr': paciente.egfr,
            'cenario': paciente.cenario,
            'local_internacao': paciente.local_internacao
        })
        
    except Exception as e:
        print_error(f"Erro ao buscar paciente {paciente_id}: {str(e)}")
        return jsonify({'error': 'Paciente não encontrado'}), 404

# ===============================
# ROTAS DE PROTOCOLO
# ===============================

@app.route('/protocolos', methods=['POST'])
def criar_protocolo():
    data = request.json
    print_request('POST', '/protocolos', {'paciente_id': data.get('paciente_id')})
    
    try:
        novo = Protocolo(
            paciente_id=data['paciente_id'],
            dieta=data.get('dieta'),
            corticoide=data.get('corticoide'),
            hepato=data.get('hepato'),
            sensibilidade=data.get('sensibilidade'),
            glicemia_atual=data.get('glicemia_atual'),
            escala_dispositivo=data.get('escala_dispositivo'),
            basal_tipo=data.get('basal_tipo'),
            nph_posologia=data.get('nph_posologia'),
            rapida_tipo=data.get('rapida_tipo'),
            bolus_threshold=data.get('bolus_threshold')
        )
        
        db.session.add(novo)
        db.session.commit()
        
        print_success(f"💊 Protocolo criado: ID={novo.id}, Paciente={novo.paciente_id}")
        print_database(f"Configurações: Dieta={novo.dieta}, Basal={novo.basal_tipo}, Sensibilidade={novo.sensibilidade}")
        
        return jsonify({
            'message': 'Protocolo salvo com sucesso', 
            'id': novo.id
        })
        
    except Exception as e:
        print_error(f"Erro ao criar protocolo: {str(e)}")
        db.session.rollback()
        return jsonify({'error': 'Erro ao salvar protocolo'}), 500

@app.route('/protocolos/<int:paciente_id>', methods=['GET'])
def buscar_protocolo_paciente(paciente_id):
    print_request('GET', f'/protocolos/{paciente_id}')
    
    try:
        protocolo = Protocolo.query.filter_by(paciente_id=paciente_id).first()
        if not protocolo:
            print_warning(f"Protocolo não encontrado para paciente {paciente_id}")
            return jsonify({'error': 'Protocolo não encontrado'}), 404
        
        print_success(f"Protocolo encontrado para paciente {paciente_id}")
        
        return jsonify({
            'id': protocolo.id,
            'dieta': protocolo.dieta,
            'corticoide': protocolo.corticoide,
            'hepato': protocolo.hepato,
            'sensibilidade': protocolo.sensibilidade,
            'glicemia_atual': protocolo.glicemia_atual,
            'escala_dispositivo': protocolo.escala_dispositivo,
            'basal_tipo': protocolo.basal_tipo,
            'nph_posologia': protocolo.nph_posologia,
            'rapida_tipo': protocolo.rapida_tipo,
            'bolus_threshold': protocolo.bolus_threshold,
            'data_protocolo': protocolo.data_protocolo.isoformat()
        })
        
    except Exception as e:
        print_error(f"Erro ao buscar protocolo: {str(e)}")
        return jsonify({'error': 'Erro interno'}), 500

# ===============================
# ROTAS DE PRESCRIÇÃO
# ===============================

@app.route('/prescricoes', methods=['POST'])
def criar_prescricao():
    data = request.json
    print_request('POST', '/prescricoes', {'paciente_id': data.get('paciente_id')})
    
    try:
        nova = Prescricao(
            paciente_id=data['paciente_id'],
            protocolo_id=data.get('protocolo_id'),
            dose_total=data.get('dose_total'),
            basal=data.get('basal'),
            prandial=data.get('prandial'),
            observacoes=data.get('observacoes')
        )
        
        db.session.add(nova)
        db.session.commit()
        
        print_success(f"📋 Prescrição criada: ID={nova.id}, TDD={nova.dose_total}U")
        print_database(f"Doses: Basal={nova.basal}U, Prandial={nova.prandial}U")
        
        return jsonify({
            'message': 'Prescrição salva', 
            'id': nova.id
        })
        
    except Exception as e:
        print_error(f"Erro ao criar prescrição: {str(e)}")
        db.session.rollback()
        return jsonify({'error': 'Erro ao salvar prescrição'}), 500

@app.route('/prescricoes/<int:paciente_id>', methods=['GET'])
def listar_prescricoes(paciente_id):
    print_request('GET', f'/prescricoes/{paciente_id}')
    
    try:
        prescricoes = Prescricao.query.filter_by(paciente_id=paciente_id).all()
        print_database(f"Encontradas {len(prescricoes)} prescrições para paciente {paciente_id}")
        
        result = [{
            'id': p.id,
            'dose_total': p.dose_total,
            'basal': p.basal,
            'prandial': p.prandial,
            'observacoes': p.observacoes,
            'data': p.data_prescricao.isoformat()
        } for p in prescricoes]
        
        print_success(f"Lista de prescrições retornada")
        return jsonify(result)
        
    except Exception as e:
        print_error(f"Erro ao listar prescrições: {str(e)}")
        return jsonify({'error': 'Erro interno'}), 500

# ===============================
# ROTAS DE ACOMPANHAMENTO
# ===============================

@app.route('/acompanhamentos', methods=['POST'])
def registrar_acompanhamento():
    data = request.json
    print_request('POST', '/acompanhamentos', {'glicemia': data.get('glicemia')})
    
    try:
        novo = Acompanhamento(
            paciente_id=data['paciente_id'],
            glicemia=data['glicemia'],
            observacao=data.get('observacao')
        )
        
        db.session.add(novo)
        db.session.commit()
        
        glicemia = data.get('glicemia', 0)
        status = "Normal" if 70 <= glicemia <= 180 else ("Hipo" if glicemia < 70 else "Hiper")
        
        print_success(f"📊 Acompanhamento registrado: Glicemia={glicemia}mg/dL ({status})")
        
        return jsonify({'message': 'Acompanhamento registrado'})
        
    except Exception as e:
        print_error(f"Erro ao registrar acompanhamento: {str(e)}")
        db.session.rollback()
        return jsonify({'error': 'Erro ao salvar acompanhamento'}), 500

@app.route('/acompanhamentos/<int:paciente_id>', methods=['GET'])
def listar_acompanhamentos(paciente_id):
    print_request('GET', f'/acompanhamentos/{paciente_id}')
    
    try:
        registros = Acompanhamento.query.filter_by(paciente_id=paciente_id).all()
        print_database(f"Encontrados {len(registros)} acompanhamentos para paciente {paciente_id}")
        
        result = [{
            'id': r.id,
            'glicemia': r.glicemia,
            'observacao': r.observacao,
            'data': r.data_registro.isoformat()
        } for r in registros]
        
        return jsonify(result)
        
    except Exception as e:
        print_error(f"Erro ao listar acompanhamentos: {str(e)}")
        return jsonify({'error': 'Erro interno'}), 500

# ===============================
# ROTAS DE ALTA
# ===============================

@app.route('/altas', methods=['POST'])
def registrar_alta():
    data = request.json
    print_request('POST', '/altas')
    
    try:
        nova = Alta(
            paciente_id=data['paciente_id'],
            resumo=data['resumo']
        )
        
        db.session.add(nova)
        db.session.commit()
        
        print_success(f"🏠 Alta registrada para paciente {nova.paciente_id}")
        
        return jsonify({'message': 'Alta registrada'})
        
    except Exception as e:
        print_error(f"Erro ao registrar alta: {str(e)}")
        db.session.rollback()
        return jsonify({'error': 'Erro ao salvar alta'}), 500

@app.route('/altas/<int:paciente_id>', methods=['GET'])
def listar_altas(paciente_id):
    print_request('GET', f'/altas/{paciente_id}')
    
    try:
        altas = Alta.query.filter_by(paciente_id=paciente_id).all()
        
        result = [{
            'id': a.id,
            'resumo': a.resumo,
            'data': a.data_alta.isoformat()
        } for a in altas]
        
        return jsonify(result)
        
    except Exception as e:
        print_error(f"Erro ao listar altas: {str(e)}")
        return jsonify({'error': 'Erro interno'}), 500

# 🔹 ROTA CORRETA: listar TODAS as altas do banco
@app.route('/altas', methods=['GET'])
def listar_todas_altas():
    try:
        altas = db.session.query(Alta, Paciente.nome).join(Paciente, Alta.paciente_id == Paciente.id).all()
        resultado = [{
            'id': alta.Alta.id,
            'nome_paciente': alta.nome,
            'resumo': alta.Alta.resumo,
            'data_alta': alta.Alta.data_alta.isoformat() if alta.Alta.data_alta else None
        } for alta in altas]

        return jsonify(resultado)
    except Exception as e:
        print("Erro ao listar todas as altas:", str(e))
        print(traceback.format_exc())
        return jsonify({'error': 'Erro ao buscar altas'}), 500



# ===============================
# HANDLERS DE ERRO
# ===============================

@app.errorhandler(404)
def not_found(error):
    print_warning(f"🔍 Rota não encontrada: {request.url}")
    return jsonify({'error': 'Rota não encontrada'}), 404

@app.errorhandler(500)
def internal_error(error):
    print_error(f"💥 Erro interno do servidor: {str(error)}")
    return jsonify({'error': 'Erro interno do servidor'}), 500

# ===============================
# INICIALIZAÇÃO
# ===============================

if __name__ == '__main__':
    print_separator()
    print_info("⚙️  Configurações do servidor:")
    print_info("🌍 Host: 0.0.0.0 (aceita conexões externas)")
    print_info("🔌 Porta: 5000")
    print_info("🐛 Debug: Ativado")
    print_database("🗄️  Banco: mysql+pymysql://root:@localhost:3306/hospital_db")
    print_separator()
    print_success("🚀 Servidor Flask iniciado com sucesso!")
    print_info("💡 Teste em: http://localhost:5000 ou http://10.0.0.186:5000")
    print_info("🏥 Health check: http://localhost:5000/health")
    print_info("🌐 Network info: http://localhost:5000/network-info")
    print_info("⏹️  Pressione CTRL+C para parar")
    print_separator()
    
    app.run(debug=True, host='0.0.0.0', port=5000)