import { LightningElement, track } from 'lwc';
import getWeather from '@salesforce/apex/WeatherService.getWeather';

export default class WeatherFinder extends LightningElement {
    @track location = '';
    @track weatherData;
    @track error;
    @track isLoading = false;

    handleLocationChange(event) {
        this.location = event.target.value;
    }

    async fetchWeather() {
        console.log('Fetch weather');
        this.isLoading = true;
        this.weatherData = null;
        this.error = null;
        
        
        try {
            const result = await getWeather({ location: this.location.replace(/\s+/g, '_') });
            console.log(JSON.parse(JSON.stringify(result)));            
        } catch (error) {
            this.error = error.body ? error.body.message : 'An unexpected error occurred.';
        } finally {
            this.isLoading = false;
        }
    }
}