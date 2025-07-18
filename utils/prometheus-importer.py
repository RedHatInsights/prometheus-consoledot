#!/usr/bin/env python3
import os, subprocess, tempfile
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/import', methods=['POST'])
def import_metrics():
    try:
        # Save file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.prom', delete=False) as f:
            f.write(request.get_data(as_text=True))
            temp_file = f.name
        
        # Run promtool
        result = subprocess.run([
            '/opt/prometheus/promtool', 'tsdb', 'create-blocks-from',
            'openmetrics', temp_file, '/var/lib/prometheus'
        ], capture_output=True, text=True)
        
        # Clean up temporal file
        os.unlink(temp_file)
        
        if result.returncode == 0:
            return jsonify({"status": "success", "output": result.stdout})
        else:
            return jsonify({"status": "error", "error": result.stderr}), 400
            
    except Exception as e:
        return jsonify({"status": "error", "error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9000, debug=False) 