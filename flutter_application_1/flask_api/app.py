from flask import Flask, request, jsonify
from flask_cors import CORS
from database import db
from models import Paciente, Prescricao, Acompanhamento, Alta

app = Flask(__name__)
CORS(app)

# Configuração MySQL (XAMPP)
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql://root:@localhost/hospital_db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db.init_app(app)

with app.app_context():
    db.create_all()

@app.route('/')
def home():
    return jsonify({
        "mensagem": "🚀 API Flask conectada com sucesso!",
        "status": "online",
        "rotas_disponiveis": [
            "/pacientes",
            "/prescricoes",
            "/acompanhamentos",
            "/altas"
        ]
    })


# ===============================
# ROTAS DE PACIENTES
# ===============================
@app.route('/pacientes', methods=['GET'])
def listar_pacientes():
    pacientes = Paciente.query.all()
    return jsonify([{
        'id': p.id,
        'nome': p.nome,
        'prontuario': p.prontuario,
        'peso': p.peso,
        'categoria': p.categoria
    } for p in pacientes])

@app.route('/pacientes', methods=['POST'])
def criar_paciente():
    data = request.json
    novo = Paciente(
        nome=data['nome'],
        prontuario=data.get('prontuario'),
        peso=data.get('peso'),
        categoria=data.get('categoria')
    )
    db.session.add(novo)
    db.session.commit()
    return jsonify({'message': 'Paciente cadastrado com sucesso', 'id': novo.id})

# ===============================
# ROTAS DE PRESCRIÇÃO
# ===============================
@app.route('/prescricoes', methods=['POST'])
def criar_prescricao():
    data = request.json
    nova = Prescricao(
        paciente_id=data['paciente_id'],
        dose_total=data['dose_total'],
        basal=data['basal'],
        prandial=data['prandial'],
        observacoes=data.get('observacoes')
    )
    db.session.add(nova)
    db.session.commit()
    return jsonify({'message': 'Prescrição salva', 'id': nova.id})

@app.route('/prescricoes/<int:paciente_id>', methods=['GET'])
def listar_prescricoes(paciente_id):
    prescricoes = Prescricao.query.filter_by(paciente_id=paciente_id).all()
    return jsonify([{
        'id': p.id,
        'dose_total': p.dose_total,
        'basal': p.basal,
        'prandial': p.prandial,
        'observacoes': p.observacoes,
        'data': p.data_prescricao.isoformat()
    } for p in prescricoes])

# ===============================
# ROTAS DE ACOMPANHAMENTO
# ===============================
@app.route('/acompanhamentos', methods=['POST'])
def registrar_acompanhamento():
    data = request.json
    novo = Acompanhamento(
        paciente_id=data['paciente_id'],
        glicemia=data['glicemia'],
        observacao=data.get('observacao')
    )
    db.session.add(novo)
    db.session.commit()
    return jsonify({'message': 'Acompanhamento registrado'})

@app.route('/acompanhamentos/<int:paciente_id>', methods=['GET'])
def listar_acompanhamentos(paciente_id):
    registros = Acompanhamento.query.filter_by(paciente_id=paciente_id).all()
    return jsonify([{
        'id': r.id,
        'glicemia': r.glicemia,
        'observacao': r.observacao,
        'data': r.data_registro.isoformat()
    } for r in registros])

# ===============================
# ROTAS DE ALTA
# ===============================
@app.route('/altas', methods=['POST'])
def registrar_alta():
    data = request.json
    nova = Alta(
        paciente_id=data['paciente_id'],
        resumo=data['resumo']
    )
    db.session.add(nova)
    db.session.commit()
    return jsonify({'message': 'Alta registrada'})

@app.route('/altas/<int:paciente_id>', methods=['GET'])
def listar_altas(paciente_id):
    altas = Alta.query.filter_by(paciente_id=paciente_id).all()
    return jsonify([{
        'id': a.id,
        'resumo': a.resumo,
        'data': a.data_alta.isoformat()
    } for a in altas])

if __name__ == '__main__':
    app.run(debug=True)
