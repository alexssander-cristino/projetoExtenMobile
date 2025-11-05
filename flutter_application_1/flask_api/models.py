from database import db
from datetime import datetime

class Paciente(db.Model):
    __tablename__ = 'pacientes'
    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(120), nullable=False)
    prontuario = db.Column(db.String(50))
    
    # 🆕 CAMPOS ATUALIZADOS (compatível com Flutter)
    sexo = db.Column(db.String(1))  # 'M' ou 'F'
    idade = db.Column(db.Integer)
    peso = db.Column(db.Float)
    altura = db.Column(db.Float)
    creatinina = db.Column(db.Float)
    local_internacao = db.Column(db.String(100))
    imc = db.Column(db.Float)
    egfr = db.Column(db.Float)  # Taxa de filtração glomerular
    cenario = db.Column(db.Integer)  # 1=Não crítico, 2=Gestante, etc.
    
    # 🔄 MANTER POR COMPATIBILIDADE
    categoria = db.Column(db.String(50))  # Campo antigo, pode manter
    data_cadastro = db.Column(db.DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f'<Paciente {self.nome}>'

class Protocolo(db.Model):
    __tablename__ = 'protocolos'
    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(db.Integer, db.ForeignKey('pacientes.id'), nullable=False)
    
    # 🩺 DADOS CLÍNICOS
    dieta = db.Column(db.String(50))  # 'NPO', 'Dieta geral', etc.
    corticoide = db.Column(db.Boolean, default=False)  # 🔄 MUDEI PARA BOOLEAN
    hepato = db.Column(db.String(50))  # Hepatopatia
    sensibilidade = db.Column(db.String(50))  # Sensibilidade à insulina
    glicemia_atual = db.Column(db.Float)
    
    # 💉 CONFIGURAÇÕES DE INSULINA
    escala_dispositivo = db.Column(db.Float)  # 1 ou 2 unidades
    basal_tipo = db.Column(db.String(100))  # Tipo de insulina basal
    nph_posologia = db.Column(db.String(100))  # Posologia NPH
    rapida_tipo = db.Column(db.String(100))  # Tipo de insulina rápida
    bolus_threshold = db.Column(db.Float)  # Limiar para bolus
    
    data_protocolo = db.Column(db.DateTime, default=datetime.utcnow)
    
    # 🔗 RELACIONAMENTO
    paciente = db.relationship('Paciente', backref=db.backref('protocolos', lazy=True))

    def __repr__(self):
        return f'<Protocolo Paciente {self.paciente_id}>'

class Prescricao(db.Model):
    __tablename__ = 'prescricoes'
    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(db.Integer, db.ForeignKey('pacientes.id'), nullable=False)
    protocolo_id = db.Column(db.Integer, db.ForeignKey('protocolos.id'))  # Opcional
    
    # 💊 DOSES CALCULADAS (compatível com Flutter)
    dose_total = db.Column(db.Float)  # TDD
    basal = db.Column(db.Float)      # Dose basal
    prandial = db.Column(db.Float)   # Dose prandial por refeição
    
    # 📝 INFORMAÇÕES ADICIONAIS
    observacoes = db.Column(db.Text)
    data_prescricao = db.Column(db.DateTime, default=datetime.utcnow)

    # 🔗 RELACIONAMENTOS
    paciente = db.relationship('Paciente', backref=db.backref('prescricoes', lazy=True))
    protocolo = db.relationship('Protocolo', backref=db.backref('prescricoes', lazy=True))

    def __repr__(self):
        return f'<Prescricao {self.paciente.nome} - TDD: {self.dose_total}U>'

class Acompanhamento(db.Model):
    __tablename__ = 'acompanhamentos'
    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(db.Integer, db.ForeignKey('pacientes.id'), nullable=False)
    
    # 📊 DADOS DE MONITORIZAÇÃO
    glicemia = db.Column(db.Float, nullable=False)  # mg/dL
    observacao = db.Column(db.Text)
    data_registro = db.Column(db.DateTime, default=datetime.utcnow)

    # 🔗 RELACIONAMENTO
    paciente = db.relationship('Paciente', backref=db.backref('acompanhamentos', lazy=True))

    def __repr__(self):
        return f'<Acompanhamento {self.paciente.nome} - {self.glicemia} mg/dL>'

class Alta(db.Model):
    __tablename__ = 'altas'
    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(db.Integer, db.ForeignKey('pacientes.id'), nullable=False)
    
    # 📋 DADOS DA ALTA
    resumo = db.Column(db.Text, nullable=False)  # Resumo obrigatório
    data_alta = db.Column(db.DateTime, default=datetime.utcnow)

    # 🔗 RELACIONAMENTO
    paciente = db.relationship('Paciente', backref=db.backref('altas', lazy=True))

    def __repr__(self):
        return f'<Alta {self.paciente.nome} - {self.data_alta.strftime("%d/%m/%Y")}>'