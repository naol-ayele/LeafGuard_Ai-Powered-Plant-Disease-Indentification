# Use Node.js LTS version
FROM node:18

# Create app directory
WORKDIR /usr/src/app

# Install dependencies
COPY package*.json ./
RUN npm install

# Bundle app source
COPY . .

# Expose the port your app runs on (e.g., 5000)
EXPOSE 3000

# Start the application
CMD [ "npm", "start" ]