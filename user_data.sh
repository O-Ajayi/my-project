#!/bin/bash

# Update the system
yum update -y

# Install nginx
amazon-linux-extras install nginx1 -y

# Create a simple index page with instance metadata
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>NLB Target Instance</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 40px; 
            background-color: #f5f5f5; 
        }
        .container { 
            background-color: white; 
            padding: 20px; 
            border-radius: 8px; 
            box-shadow: 0 2px 4px rgba(0,0,0,0.1); 
        }
        .header { 
            color: #333; 
            border-bottom: 2px solid #007acc; 
            padding-bottom: 10px; 
        }
        .info { 
            margin: 20px 0; 
        }
        .label { 
            font-weight: bold; 
            color: #555; 
        }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">🎯 NLB Target Instance</h1>
        <div class="info">
            <p><span class="label">Instance ID:</span> <span id="instance-id">Loading...</span></p>
            <p><span class="label">Private IP:</span> <span id="private-ip">Loading...</span></p>
            <p><span class="label">Availability Zone:</span> <span id="az">Loading...</span></p>
            <p><span class="label">Instance Type:</span> <span id="instance-type">Loading...</span></p>
            <p><span class="label">Timestamp:</span> <span id="timestamp"></span></p>
            <p><span class="label">Request Count:</span> <span id="request-count">1</span></p>
        </div>
        <div class="info">
            <h3>Health Check Status: <span style="color: green;">✅ Healthy</span></h3>
            <p>This instance is ready to receive traffic from the Network Load Balancer.</p>
        </div>
    </div>

    <script>
        // Update timestamp
        document.getElementById('timestamp').textContent = new Date().toISOString();
        
        // Increment request counter
        let count = localStorage.getItem('requestCount') || 0;
        count++;
        localStorage.setItem('requestCount', count);
        document.getElementById('request-count').textContent = count;

        // Fetch instance metadata
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data)
            .catch(() => document.getElementById('instance-id').textContent = 'Not available');

        fetch('http://169.254.169.254/latest/meta-data/local-ipv4')
            .then(response => response.text())
            .then(data => document.getElementById('private-ip').textContent = data)
            .catch(() => document.getElementById('private-ip').textContent = 'Not available');

        fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone')
            .then(response => response.text())
            .then(data => document.getElementById('az').textContent = data)
            .catch(() => document.getElementById('az').textContent = 'Not available');

        fetch('http://169.254.169.254/latest/meta-data/instance-type')
            .then(response => response.text())
            .then(data => document.getElementById('instance-type').textContent = data)
            .catch(() => document.getElementById('instance-type').textContent = 'Not available');
    </script>
</body>
</html>
EOF

# Configure nginx to listen on the specified port
sed -i "s/listen       80/listen       ${port}/" /etc/nginx/nginx.conf
sed -i "s/listen       \[::\]:80/listen       \[::\]:${port}/" /etc/nginx/nginx.conf

# Start and enable nginx
systemctl start nginx
systemctl enable nginx

# Create a health check endpoint
cat > /var/www/html/health << 'EOF'
OK
EOF

# Set proper permissions
chown -R nginx:nginx /var/www/html
chmod -R 755 /var/www/html

# Configure firewall to allow traffic on the specified port
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=${port}/tcp
    firewall-cmd --reload
fi

# Log that setup is complete
echo "$(date): NLB target instance setup complete. Nginx running on port ${port}" >> /var/log/nlb-setup.log